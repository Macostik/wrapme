//
//  WLChatViewController.m
//  meWrap
//
//  Created by Ravenpod on 09.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSObject+NibAdditions.h"
#import "WLChat.h"
#import "WLChatViewController.h"
#import "WLComposeBar.h"
#import "WLKeyboard.h"
#import "WLStreamLoadingView.h"
#import "WLMessageCell.h"
#import "WLSoundPlayer.h"
#import "WLFontPresetter.h"
#import "WLMessageDateView.h"
#import "WLWrapViewController.h"
#import "WLEntryPresenter.h"
#import "WLToast.h"
#import "WLBadgeLabel.h"
#import "WLMessagesCounter.h"
#import "PlaceholderView.h"
#import "WLEntry+WLUploadingQueue.h"
#import "WLNetwork.h"
#import "WLImageView.h"

CGFloat WLMaxTextViewWidth;
CGFloat WLMinTextViewWidth;

@interface WLChatViewController () <StreamViewDelegate, WLComposeBarDelegate, WLKeyboardBroadcastReceiver, EntryNotifying, WLChatDelegate>

@property (weak, nonatomic) IBOutlet StreamView *streamView;

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@property (weak, nonatomic) IBOutlet UIView *typingView;

@property (weak, nonatomic) IBOutlet UILabel *typingUserNamesTextField;

@property (weak, nonatomic) IBOutlet WLImageView *typingUserAvatarView;

@property (weak, nonatomic) id operation;

@property (nonatomic) BOOL typing;

@property (nonatomic) BOOL reloading;

@property (strong, nonatomic) WLChat *chat;

@property (strong, nonatomic) UIFont* nameFont;

@property (strong, nonatomic) UIFont* messageFont;

@property (strong, nonatomic) NSMapTable* cachedMessageHeights;

@property (strong, nonatomic) StreamMetrics *messageMetrics;
@property (strong, nonatomic) StreamMetrics *messageWithNameMetrics;
@property (strong, nonatomic) StreamMetrics *myMessageMetrics;
@property (strong, nonatomic) StreamMetrics *dateMetrics;
@property (strong, nonatomic) StreamMetrics *unreadMessagesMetrics;
@property (strong, nonatomic) StreamMetrics *placeholderMetrics;

@property (nonatomic) BOOL dragged;

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
    [self.chat resetEntries:self.wrap.messages];
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
        self.messageMetrics = [[StreamMetrics alloc] initWithIdentifier:@"WLMessageCell"];
        self.messageMetrics.selectable = NO;
        self.messageWithNameMetrics = [[StreamMetrics alloc] initWithIdentifier:@"WLMessageWithNameCell"];
        self.messageWithNameMetrics.selectable = NO;
        self.myMessageMetrics = [[StreamMetrics alloc] initWithIdentifier:@"WLMyMessageCell"];
        self.myMessageMetrics.selectable = NO;
        self.dateMetrics = [[StreamMetrics alloc] initWithIdentifier:@"WLMessageDateView" size:33];
        self.dateMetrics.selectable = NO;
        self.unreadMessagesMetrics = [[StreamMetrics alloc] initWithIdentifier:@"WLUnreadMessagesView" size:46];
        self.unreadMessagesMetrics.selectable = NO;
        __weak typeof(self)weakSelf = self;
        self.placeholderMetrics = [[StreamMetrics alloc] initWithIdentifier:@"NoMessagePlaceholderView" initializer:^(StreamMetrics * metrics) {
            [metrics setPrepareAppearing:^(StreamItem *item, id entry) {
                PlaceholderView *placeholderView = (id)item.view;
                placeholderView.textLabel.text = [NSString stringWithFormat:@"no_chat_message".ls, weakSelf.wrap.name];
            }];
        }];
        self.placeholderMetrics.selectable = NO;
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self updateInsets:YES];
    
    if (!self.wrap) {
        __weak typeof(self)weakSelf = self;
        run_after(0.5, ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
        return;
    }
    
    self.cachedMessageHeights = [NSMapTable strongToStrongObjectsMapTable];

    self.messageFont = [UIFont fontSmall];
    self.nameFont = [UIFont lightFontSmaller];
    
    __weak typeof(self)weakSelf = self;
    
    void (^finalizeMessageAppearing)(StreamItem *, id) = ^(StreamItem *item, Message *message) {
        if (message.unread && weakSelf.view.superview && ![weakSelf.chat.readMessages containsObject:message]) {
            [weakSelf.chat.readMessages addObject:message];
        }
        WLMessageCell *messageCell = (id)item.view;
        messageCell.tailView.hidden = ![weakSelf.chat.groupMessages containsObject:message];
    };
    
    self.messageWithNameMetrics.finalizeAppearing = finalizeMessageAppearing;
    self.myMessageMetrics.finalizeAppearing = finalizeMessageAppearing;
    self.messageMetrics.finalizeAppearing = finalizeMessageAppearing;
    
    WLMinTextViewWidth = WLConstants.screenWidth - WLLeadingBubbleIndentWithAvatar - 2*WLMessageHorizontalInset - WLBubbleIndent;
    WLMaxTextViewWidth = WLConstants.screenWidth - 2*WLBubbleIndent - 2*WLMessageHorizontalInset;
    
    self.messageWithNameMetrics.sizeAt = self.messageMetrics.sizeAt = self.myMessageMetrics.sizeAt = ^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
        Message *message = [weakSelf.chat.entries tryAt:position.index];
        return [weakSelf heightOfMessageCell:message];
    };
    
    self.messageWithNameMetrics.insetsAt = self.messageMetrics.insetsAt = self.myMessageMetrics.insetsAt = ^CGRect(StreamPosition *position, StreamMetrics *metrics) {
        Message *message = [weakSelf.chat.entries tryAt:position.index];
        return  [weakSelf.chat.messagesWithDay containsObject:message] ?
                CGRectZero : [weakSelf.chat.groupMessages containsObject:message] ? CGRectMake(0, WLMessageGroupSpacing, 0, 0) : CGRectMake(0, 2, 0, 0);
    };
	
    self.chat = [WLChat chatWithWrap:self.wrap];
    self.chat.delegate = self;

    if (self.wrap.messages.nonempty) {
        [self refreshMessages:^{
        } failure:^(NSError *error) {
            [error showIgnoringNetworkError];
        }];
    }
    
    [[Message notifier] addReceiver:self];
    [[WLFontPresetter defaultPresetter] addReceiver:self];
    
    [self.streamView.panGestureRecognizer addTarget:self action:@selector(dragging:)];
    
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.streamView unlock];
    [[WLMessagesCounter instance] update:nil];
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
    [[WLMessagesCounter instance] update:nil];
    [self.chat.unreadMessages minusSet:[self.chat.readMessages set]];
    [self updateBadge];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)scrollToLastUnreadMessage {
    __weak typeof(self)weakSelf = self;
    StreamItem *unreadMessagesItem = [self.streamView itemPassingTest:^BOOL(StreamItem *item) {
        return item.metrics == weakSelf.unreadMessagesMetrics;
    }];
    [self.streamView scrollToItem:unreadMessagesItem animated:NO];
}

- (void)setShowKeyboard:(BOOL)showKeyboard {
    _showKeyboard = showKeyboard;
    if (self.isViewLoaded && showKeyboard) {
        [self.composeBar becomeFirstResponder];
    }
}

- (void)updateInsets:(BOOL)typingViewHidden {
    CGFloat bottom = self.composeBar.height + [WLKeyboard keyboard].height + (typingViewHidden ? 0 : self.typingView.height) + WLBubbleIndent;
    self.streamView.contentInset = self.streamView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, bottom, 0);
}

- (void)keyboardWillShow:(WLKeyboard *)keyboard {
    [super keyboardWillShow:keyboard];
    __weak typeof(self)weakSelf = self;
    [keyboard performAnimation:^{
        weakSelf.streamView.transform = CGAffineTransformMakeTranslation(0, -keyboard.height);
    }];
}

- (void)keyboardDidShow:(WLKeyboard *)keyboard {
    [super keyboardDidShow:keyboard];
    [UIView performWithoutAnimation:^{
        self.streamView.transform = CGAffineTransformIdentity;
        [self updateInsets:self.typingView.hidden];
        self.streamView.contentOffset = CGPointMake(0, MIN(self.streamView.maximumContentOffset.y, self.streamView.contentOffset.y + keyboard.height));
    }];
}

- (void)keyboardWillHide:(WLKeyboard *)keyboard {
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

- (void)keyboardDidHide:(WLKeyboard *)keyboard {
    [super keyboardDidHide:keyboard];
    [UIView performWithoutAnimation:^{
        [self updateInsets:self.typingView.hidden];
    }];
}

- (void)insertMessage:(Message*)message {
    
    if (self.streamView.locks > 0) {
        [self.chat addEntry:message];
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    runUnaryQueuedOperation(@"wl_chat_insertion_queue", ^(WLOperation *operation) {
        
        StreamView *streamView = weakSelf.streamView;
        
        if ([weakSelf.chat.entries containsObject:message]) {
            [operation finish];
        } else  {
            [weakSelf.chat addEntry:message];
            CGPoint offset = streamView.contentOffset;
            CGPoint maximumOffset = streamView.maximumContentOffset;
            if (!streamView.scrollable || offset.y < maximumOffset.y) {
                [operation finish];
            } else {
                if (streamView.height/2 < [weakSelf heightOfMessageCell:message] && [self.chat.unreadMessages count] == 1) {
                    [weakSelf scrollToLastUnreadMessage];
                } else {
                    [streamView reload];
                    streamView.contentOffset = CGPointOffset(streamView.maximumContentOffset, 0, -[weakSelf heightOfMessageCell:message]);
                    [streamView setMaximumContentOffsetAnimated:YES];
                }
                run_after(0.5, ^{
                    [operation finish];
                });
            }
        }
    });
}

- (void)refreshMessages:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    Message* message = [self.chat.entries lastObject];
    if (!message) {
        [self loadMessages:success failure:failure];
        return;
    }
    [self.wrap messagesNewer:message.createdAt success:^(NSArray *messages) {
        if (!weakSelf.wrap.messages.nonempty) weakSelf.chat.completed = YES;
        [weakSelf.chat addEntries:[messages set]];
        if (success) success();
    } failure:failure];
}

- (void)loadMessages:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [self.wrap messages:^(NSArray *messages) {
        weakSelf.chat.completed = messages.count < [NSUserDefaults standardUserDefaults].pageSize;
		[weakSelf.chat resetEntries:[messages set]];
        if (success) success();
    } failure:failure];
}

- (void)appendMessages:(WLBlock)success failure:(WLFailureBlock)failure {
	if (self.operation) return;
	__weak typeof(self)weakSelf = self;
    Message* olderMessage = [self.chat.entries firstObject];
    Message* newerMessage = [self.chat.entries lastObject];
    if (!olderMessage) {
        [self loadMessages:success failure:failure];
        return;
    }
	self.operation = [self.wrap messagesOlder:olderMessage.createdAt newer:newerMessage.createdAt success:^(NSArray *messages) {
		weakSelf.chat.completed = messages.count < [NSUserDefaults standardUserDefaults].pageSize;
        [weakSelf.chat addEntries:[messages set]];
        if (success) success();
	} failure:failure];
}

#pragma mark - WLChatDelegate

- (void)chatDidChangeMessagesWithName:(WLChat *)chat {
    [self.cachedMessageHeights removeAllObjects];
}

- (void)setDidChange:(WLPaginatedSet *)group {
    [self reloadData];
}

- (void)updateTypingView:(WLChat*)chat {
    BOOL someoneIsTyping = chat.typingUsers.nonempty;
    if (someoneIsTyping) {
        NSString *typingNames = chat.typingNames;
        self.typingUserNamesTextField.text = typingNames;
        self.typingUserAvatarView.hidden = self.typingUserNamesTextField.hidden = NO;
        User *user = chat.typingUsers.firstObject;
        if (chat.typingUsers.count == 1 && user.valid) {
            self.typingUserAvatarView.url = user.picture.small;
        } else {
            self.typingUserAvatarView.url = nil;
            [self.typingUserAvatarView setImage:[UIImage imageNamed:@"friends"]];
        }
    } else {
        self.typingUserNamesTextField.text = nil;
        self.typingUserAvatarView.url = nil;
        self.typingUserAvatarView.image = nil;
        self.typingUserAvatarView.hidden = self.typingUserNamesTextField.hidden = YES;
    }
}

- (void)chat:(WLChat*)chat didBeginTyping:(User *)user {
    [self updateTypingView:chat];
    [self setTypingViewHidden:NO];
}
    
- (void)chat:(WLChat*)chat didEndTyping:(User *)user {
    [self updateTypingView:chat];
    [self setTypingViewHidden:chat.typingUsers.count == 0];
}

- (void)reloadData {
    __weak typeof(self)weakSelf = self;
    if (self.reloading) {
        return;
    }
    self.reloading = YES;
    runUnaryQueuedOperation(@"wl_chat_insertion_queue", ^(WLOperation *operation) {
        [weakSelf.streamView reload];
        [operation finish];
        weakSelf.reloading = NO;
    });
}

- (void)updateBadge {
    self.badge.intValue = self.chat.unreadMessages.count;
}

#pragma mark - EntryNotifying

- (void)notifier:(EntryNotifier *)notifier didAddEntry:(Message *)message {
    [self insertMessage:message];
}

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(Entry *)entry {
    [self reloadData];
}

- (void)notifier:(EntryNotifier *)notifier willDeleteEntry:(Entry *)entry {
    [self.chat removeEntry:entry];
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

- (void)dragging:(UIPanGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if ([sender translationInView:self.streamView].y <= 0) {
            [self setTypingViewHidden:!self.chat.typingUsers.nonempty];
        } else if (self.streamView.scrollable) {
            [self setTypingViewHidden:YES];
        }
    }
}

- (void)setTypingViewHidden:(BOOL)hidden {
    if (self.typingView.hidden != hidden) {
        BOOL scroll = NO;
        if (hidden) {
            [self.typingView addAnimation:[CATransition transition:kCATransitionPush subtype:kCATransitionFromBottom duration:0.2]];
        } else {
            scroll = ABS(self.streamView.contentOffset.y - self.streamView.maximumContentOffset.y) < 5;
            [self.typingView addAnimation:[CATransition transition:kCATransitionPush subtype:kCATransitionFromTop duration:0.2]];
        }
        [self updateInsets:hidden];
        self.typingView.hidden = hidden;
        
        if (scroll) {
            [self.streamView setMaximumContentOffsetAnimated:YES];
        }
    }
}

#pragma mark - WLComposeBarDelegate

- (void)sendMessageWithText:(NSString*)text {
    if (self.wrap.valid) {
        self.streamView.contentOffset = self.streamView.maximumContentOffset;
        [self.wrap uploadMessage:text success:^(Message *message) {
        } failure:^(NSError *error) {
        }];
        [WLSoundPlayer playSound:WLSound_s04];
        [self.chat markAsRead];
    } else {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
    self.typing = NO;
	[self sendMessageWithText:text];
}

- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar *)composeBar {
	return NO;
}

- (void)setTyping:(BOOL)typing {
    if (_typing != typing) {
        _typing = typing;
        [self enqueueSelectorPerforming:@selector(sendTypingStateChange) afterDelay:1.0f];
    }
}

- (void)sendTypingStateChange {
    [self.chat sendTyping:_typing];
}

- (void)composeBarDidChangeText:(WLComposeBar*)composeBar {
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
    if ([self.chat.messagesWithDay containsObject:message]) {
        [metrics addObject:self.dateMetrics];
    }
    if (message.contributor.current) {
        [metrics addObject:self.myMessageMetrics];
    } else if ([self.chat.messagesWithName containsObject:message]) {
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
            offset.y += streamView.contentSize.height - oldContentSize.height;
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

- (CGFloat)heightOfMessageCell:(Message *)message {
    NSNumber *cachedHeight = [self.cachedMessageHeights objectForKey:message];
    if (cachedHeight) {
        return [cachedHeight floatValue];
    }
    if (!self.messageFont) {
        return 0;
    }
    BOOL containsName = [self.chat.messagesWithName containsObject:message];
    CGFloat calculateWight = message.contributor.current ? WLMaxTextViewWidth : WLMinTextViewWidth;
    CGFloat commentHeight = [message.text heightWithFont:self.messageFont width:calculateWight];
    CGFloat topInset = containsName ? self.nameFont.lineHeight + WLNameVerticalInset : 0;
    CGFloat bottomInset = self.nameFont.lineHeight + WLMessageVerticalInset;
    commentHeight += topInset + bottomInset;
    commentHeight = MAX (containsName ? WLMessageWithNameMinimumCellHeight : WLMessageWithoutNameMinimumCellHeight, commentHeight);
    [self.cachedMessageHeights setObject:@(commentHeight) forKey:message];
    return commentHeight;
}

- (void)refreshUnreadMessagesAfterDragging {
    if (self.chat.unreadMessages.count == 0) {
        [self updateBadge];
        return;
    }
    
    [self.chat markAsRead];
    
    [[WLMessagesCounter instance] update:nil];
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
    if (reachedRequiredOffset && [WLNetwork sharedNetwork].reachable && !self.chat.completed) {
        __weak typeof(self)weakSelf = self;
        if (weakSelf.chat.wrap) {
            [weakSelf appendMessages:^{
            } failure:^(NSError *error) {
                [error showIgnoringNetworkError];
            }];
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    [self appendItemsIfNeededWithTargetContentOffset:*targetContentOffset];
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self.cachedMessageHeights removeAllObjects];
    self.messageFont = [UIFont fontSmall];
    self.nameFont = [UIFont lightFontSmaller];
    [self reloadData];
}

@end
