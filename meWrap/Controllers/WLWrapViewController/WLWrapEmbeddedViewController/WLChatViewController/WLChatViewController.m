//
//  WLChatViewController.m
//  meWrap
//
//  Created by Ravenpod on 09.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLChatViewController.h"
#import "WLWrapViewController.h"

@interface WLChatViewController () <StreamViewDelegate, ComposeBarDelegate, KeyboardNotifying, EntryNotifying, ChatNotifying>

@property (weak, nonatomic) IBOutlet StreamView *streamView;

@property (weak, nonatomic) IBOutlet ComposeBar *composeBar;

@property (nonatomic) BOOL typing;

@property (nonatomic) BOOL reloading;

@property (strong, nonatomic) Chat *chat;

@property (strong, nonatomic) StreamMetrics *messageMetrics;
@property (strong, nonatomic) StreamMetrics *messageWithNameMetrics;
@property (strong, nonatomic) StreamMetrics *myMessageMetrics;
@property (strong, nonatomic) StreamMetrics *dateMetrics;
@property (strong, nonatomic) StreamMetrics *unreadMessagesMetrics;
@property (strong, nonatomic) StreamMetrics *placeholderMetrics;

@property (nonatomic) BOOL dragged;

@property (strong, nonatomic) RunQueue *runQueue;

@end

@implementation WLChatViewController

@dynamic delegate;

- (void)dealloc {
    self.streamView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)applicationDidBecomeActive {
    [self.streamView unlock];
    [self.chat resetMessages];
    [self scrollToLastUnreadMessage];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)applicationWillResignActive {
    [self.streamView lock];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.runQueue = [[RunQueue alloc] initWithLimit:1];
        self.messageMetrics = [[StreamMetrics alloc] initWithIdentifier:@"MessageCell"];
        self.messageMetrics.selectable = NO;
        self.messageWithNameMetrics = [[StreamMetrics alloc] initWithIdentifier:@"MessageWithNameCell"];
        self.messageWithNameMetrics.selectable = NO;
        self.myMessageMetrics = [[StreamMetrics alloc] initWithIdentifier:@"MyMessageCell"];
        self.myMessageMetrics.selectable = NO;
        self.dateMetrics = [MessageDateView layoutMetrics];
        self.dateMetrics.selectable = NO;
        self.unreadMessagesMetrics = [[StreamMetrics alloc] initWithIdentifier:@"WLUnreadMessagesView" size:46];
        self.unreadMessagesMetrics.selectable = NO;
        __weak typeof(self)weakSelf = self;
        self.placeholderMetrics = [[[StreamMetrics alloc] initWithLoader:[[PlaceholderLoader alloc] initWithIdentifier:@"chat"]] change:^(StreamMetrics *metrics) {
            [metrics setPrepareAppearing:^(StreamItem *item, StreamReusableView *view) {
                PlaceholderView *placeholderView = (id)view;
                placeholderView.textLabel.text = [NSString stringWithFormat:@"no_chat_message".ls, weakSelf.wrap.name];
            }];
        }];
        self.placeholderMetrics.selectable = NO;
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self updateInsets];
    
    if (!self.wrap) {
        __weak typeof(self)weakSelf = self;
        [[Dispatch mainQueue] after:0.5 block:^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }];
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    
    void (^finalizeMessageAppearing)(StreamItem *, id) = ^(StreamItem *item, StreamReusableView *view) {
        Message *message = item.entry;
        if (message.unread && weakSelf.view.superview && ![weakSelf.chat.readMessages containsObject:message]) {
            [weakSelf.chat addReadMessage:message];
        }
        MessageCell *messageCell = (MessageCell*)view;
        messageCell.tailView.hidden = !message.chatMetadata.isGroup;
    };
    
    self.messageWithNameMetrics.finalizeAppearing = finalizeMessageAppearing;
    self.myMessageMetrics.finalizeAppearing = finalizeMessageAppearing;
    self.messageMetrics.finalizeAppearing = finalizeMessageAppearing;
    
    self.messageWithNameMetrics.sizeAt = self.messageMetrics.sizeAt = self.myMessageMetrics.sizeAt = ^CGFloat(StreamItem *item) {
        Message *message = item.entry;
        return [weakSelf.chat heightOfMessageCell:message];
    };
    
    self.messageWithNameMetrics.insetsAt = self.messageMetrics.insetsAt = self.myMessageMetrics.insetsAt = ^CGRect(StreamItem *item) {
        Message *message = item.entry;
        return CGRectMake(0, message.chatMetadata.containsDate ? 0 : message.chatMetadata.isGroup ? Chat.MessageGroupSpacing : 2, 0, 0);
    };
	
    self.chat = [[Chat alloc] initWithWrap:self.wrap];
    [self.chat addReceiver:self];

    if (self.wrap.messages.nonempty) {
        [self.chat newer:nil failure:^(NSError * _Nullable error) {
            [error showNonNetworkError];
        }];
    }
    
    [[Message notifier] addReceiver:self];
    [[FontPresetter defaultPresetter] addReceiver:self];
    
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.streamView unlock];
    [self.chat sort];
    [self scrollToLastUnreadMessage];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    if (self.showKeyboard) {
        [self.composeBar becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.streamView lock];
    [self.chat markAsRead];
    [self updateBadge];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)scrollToLastUnreadMessage {
    __weak typeof(self)weakSelf = self;
    [self.streamView scrollToItemPassingTest:^BOOL(StreamItem *item) {
        return item.metrics == weakSelf.unreadMessagesMetrics;
    } animated:NO];
}

- (void)setShowKeyboard:(BOOL)showKeyboard {
    _showKeyboard = showKeyboard;
    if (self.isViewLoaded && showKeyboard) {
        [self.composeBar becomeFirstResponder];
    }
}

- (void)updateInsets {
    CGFloat bottom = self.composeBar.height + [Keyboard keyboard].height + Chat.BubbleIndent;
    self.streamView.contentInset = self.streamView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, bottom, 0);
}

- (void)keyboardWillShow:(Keyboard *)keyboard {
    [super keyboardWillShow:keyboard];
    __weak typeof(self)weakSelf = self;
    if (self.streamView.contentInset.bottom > self.composeBar.height + Chat.BubbleIndent) return;
    [keyboard performAnimation:^{
        weakSelf.streamView.transform = CGAffineTransformMakeTranslation(0, -keyboard.height);
    }];
}

- (void)keyboardDidShow:(Keyboard *)keyboard {
    [super keyboardDidShow:keyboard];
    [UIView performWithoutAnimation:^{
        self.streamView.transform = CGAffineTransformIdentity;
        [self updateInsets];
        self.streamView.contentOffset = CGPointMake(0, MIN(self.streamView.maximumContentOffset.y, self.streamView.contentOffset.y + keyboard.height));
    }];
}

- (void)keyboardWillHide:(Keyboard *)keyboard {
    [super keyboardWillHide:keyboard];
    [UIView performWithoutAnimation:^{
        CGFloat height = MAX(0, self.streamView.contentOffset.y - keyboard.height);
        self.streamView.transform = CGAffineTransformMakeTranslation(0, height - self.streamView.contentOffset.y);
        [self.streamView trySetContentOffset:CGPointMake(0, height)];
    }];
    __weak typeof(self)weakSelf = self;
    [keyboard performAnimation:^{
        weakSelf.streamView.transform = CGAffineTransformIdentity;
    }];
}

- (void)keyboardDidHide:(Keyboard *)keyboard {
    [super keyboardDidHide:keyboard];
    [UIView performWithoutAnimation:^{
        [self updateInsets];
    }];
}

- (void)insertMessage:(Message*)message {
    if (self.streamView.locks > 0) {
        [self.chat add:message];
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    [self.runQueue run:^(Block finish) {
        StreamView *streamView = weakSelf.streamView;
        
        if ([weakSelf.chat.entries containsObject:message]) {
            finish();
        } else  {
            [weakSelf.chat add:message];
            CGPoint offset = streamView.contentOffset;
            CGPoint maximumOffset = streamView.maximumContentOffset;
            if (!streamView.scrollable || offset.y < maximumOffset.y) {
                finish();
            } else {
                if (streamView.height/2 < [weakSelf.chat heightOfMessageCell:message] && [self.chat.unreadMessages count] == 1) {
                    [weakSelf scrollToLastUnreadMessage];
                } else {
                    [streamView reload];
                    streamView.contentOffset = CGPointOffset(streamView.maximumContentOffset, 0, -[weakSelf.chat heightOfMessageCell:message]);
                    [streamView setMaximumContentOffsetAnimated:YES];
                }
                [[Dispatch mainQueue] after:0.5 block:finish];
            }
        }
    }];
}

#pragma mark - ChatNotifying

- (void)listChanged:(List *)list {
    [self reloadData];
}

- (void)chat:(Chat*)chat didBeginTyping:(User *)user {
    NSString *userName = [chat.typingUsers.firstObject name];
    if (self.typingHalper && userName.nonempty) {
        self.typingHalper([NSString stringWithFormat:@"formatted_is_typing".ls, userName]);
    }
}
    
- (void)chat:(Chat*)chat didEndTyping:(User *)user {
    NSString *userName = [chat.typingUsers.firstObject name];
    if (self.typingHalper) {
        self.typingHalper(userName.nonempty ? [NSString stringWithFormat:@"formatted_is_typing".ls, userName] : nil);
    }
}

- (void)reloadData {
    __weak typeof(self)weakSelf = self;
    if (self.reloading) {
        return;
    }
    self.reloading = YES;
    [self.runQueue run:^(Block finish) {
        [weakSelf.streamView reload];
        finish();
        weakSelf.reloading = NO;
    }];
}

- (void)updateBadge {
    self.badge.value = self.chat.unreadMessages.count;
}

#pragma mark - EntryNotifying

- (void)notifier:(EntryNotifier *)notifier didAddEntry:(Message *)message {
    [self insertMessage:message];
}

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(Entry *)entry event:(enum EntryUpdateEvent)event {
    [self reloadData];
}

- (void)notifier:(EntryNotifier *)notifier willDeleteEntry:(Entry *)entry {
    [self.chat remove:entry];
    if (entry.unread) {
        [self updateBadge];
    }
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return self.wrap == entry.container;
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
    [self.composeBar resignFirstResponder];
    self.typing = NO;
    if (self.wrap.valid) {
        [self.navigationController popViewControllerAnimated:NO];
    } else {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

#pragma mark - ComposeBarDelegate

- (void)sendMessageWithText:(NSString*)text {
    if (self.wrap.valid) {
        self.streamView.contentOffset = self.streamView.maximumContentOffset;
        [self.wrap uploadMessage:text];
        [[SoundPlayer player] play:Sounds04];
        [self.chat markAsRead];
    } else {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)composeBar:(ComposeBar *)composeBar didFinishWithText:(NSString *)text {
    self.typing = NO;
	[self sendMessageWithText:text];
}

- (BOOL)composeBarDidShouldResignOnFinish:(ComposeBar *)composeBar {
	return NO;
}

- (void)setTyping:(BOOL)typing {
    if (_typing != typing) {
        _typing = typing;
        [self enqueueSelector:@selector(sendTypingStateChange) delay:1.0f];
    }
}

- (void)sendTypingStateChange {
    [self.chat sendTyping:_typing];
}

- (void)composeBarDidChangeText:(ComposeBar*)composeBar {
    self.typing = composeBar.text.nonempty;
}

// MARK: - StreamViewDelegate

- (NSInteger)streamView:(StreamView*)streamView numberOfItemsInSection:(NSInteger)section {
    [self updateBadge];
    return [self.chat.entries count];
}

- (id  _Nullable (^)(StreamItem * _Nonnull))streamView:(StreamView *)streamView entryBlockForItem:(StreamItem *)item {
    __weak typeof(self)weakSelf = self;
    return ^id (StreamItem *item) {
        return [weakSelf.chat.entries tryAt:item.position.index];
    };
}

- (NSArray*)streamView:(StreamView*)streamView metricsAt:(StreamPosition*)position {
    NSMutableArray *metrics = [NSMutableArray array];
    Message *message = [self.chat.entries tryAt:position.index];
    if ([self.chat.unreadMessages firstObject] == message) {
        [metrics addObject:self.unreadMessagesMetrics];
    }
    if (message.chatMetadata.containsDate) {
        [metrics addObject:self.dateMetrics];
    }
    if (message.contributor.current) {
        [metrics addObject:self.myMessageMetrics];
    } else if (message.chatMetadata.containsName) {
        [metrics addObject:self.messageWithNameMetrics];
    } else {
        [metrics addObject:self.messageMetrics];
    }
    return metrics;
}

- (void)streamViewDidChangeContentSize:(StreamView * __nonnull)streamView oldContentSize:(CGSize)oldContentSize {
    if (streamView.scrollable) {
        if (self.dragged) {
            CGPoint offset = streamView.contentOffset;
            CGFloat unreadContentOffset = self.chat.unreadMessages.count == 0? self.unreadMessagesMetrics.size : 0;
            offset.y += streamView.contentSize.height - oldContentSize.height + unreadContentOffset;
            streamView.contentOffset = offset;
        } else {
            streamView.contentOffset = streamView.maximumContentOffset;
        }
    }
    [self appendItemsIfNeededWithTargetContentOffset:streamView.contentOffset];
}

- (StreamMetrics *)streamViewPlaceholderMetrics:(StreamView *)streamView {
    return self.placeholderMetrics;
}

- (void)refreshUnreadMessagesAfterDragging {
    if (self.chat.unreadMessages.count == 0) {
        [self updateBadge];
        return;
    }
    
    [self.chat markAsRead];
    [self.chat sort];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self refreshUnreadMessagesAfterDragging];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.dragged = YES;
    if (!decelerate) {
        [self refreshUnreadMessagesAfterDragging];
    }
}

- (void)appendItemsIfNeededWithTargetContentOffset:(CGPoint)targetContentOffset {
    StreamView *streamView = self.streamView;
    BOOL reachedRequiredOffset = reachedRequiredOffset = (targetContentOffset.y - streamView.minimumContentOffset.y) < streamView.fittingContentHeight;
    if (reachedRequiredOffset && [Network sharedNetwork].reachable && !self.chat.completed) {
        __weak typeof(self)weakSelf = self;
        if (weakSelf.chat.wrap) {
            [self.chat older:nil failure:^(NSError * _Nullable error) {
                [error showNonNetworkError];
            }];
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    [self appendItemsIfNeededWithTargetContentOffset:*targetContentOffset];
}

@end
