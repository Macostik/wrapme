//
//  WLChatViewController.m
//  meWrap
//
//  Created by Ravenpod on 09.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSDate+Additions.h"
#import "NSObject+NibAdditions.h"
#import "UIFont+CustomFonts.h"
#import "UIScrollView+Additions.h"
#import "UIView+AnimationHelper.h"
#import "WLChat.h"
#import "WLChatViewController.h"
#import "WLComposeBar.h"
#import "WLKeyboard.h"
#import "WLStreamLoadingView.h"
#import "WLMessageCell.h"
#import "WLRefresher.h"
#import "WLSoundPlayer.h"
#import "WLFontPresetter.h"
#import "WLMessageDateView.h"
#import "WLWrapViewController.h"
#import "WLEntryPresenter.h"
#import "WLToast.h"
#import "WLBadgeLabel.h"
#import "WLMessagesCounter.h"
#import "PlaceholderView.h"
#import "WLLayoutPrioritizer.h"
#import "UIView+QuatzCoreAnimations.h"

CGFloat WLMaxTextViewWidth;

@interface WLChatViewController () <StreamViewDelegate, WLComposeBarDelegate, WLKeyboardBroadcastReceiver, WLEntryNotifyReceiver, WLChatDelegate>

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

@property (strong, nonatomic) UIFont* timeFont;

@property (weak, nonatomic) WLRefresher* refresher;

@property (strong, nonatomic) NSMapTable* cachedMessageHeights;

@property (strong, nonatomic) StreamMetrics *messageMetrics;
@property (strong, nonatomic) StreamMetrics *myMessageMetrics;
@property (strong, nonatomic) StreamMetrics *dateMetrics;
@property (strong, nonatomic) StreamMetrics *unreadMessagesMetrics;
@property (strong, nonatomic) StreamMetrics *loadingViewMetrics;
@property (strong, nonatomic) StreamMetrics *placeholderMetrics;

@property (nonatomic) BOOL dragged;

@end

@implementation WLChatViewController

@dynamic delegate;

- (void)dealloc {
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
        self.myMessageMetrics = [[StreamMetrics alloc] initWithIdentifier:@"WLMyMessageCell"];
        self.dateMetrics = [[StreamMetrics alloc] initWithIdentifier:@"WLMessageDateView" size:31];
        self.unreadMessagesMetrics = [[StreamMetrics alloc] initWithIdentifier:@"WLUnreadMessagesView" size:48];
        self.loadingViewMetrics = [WLStreamLoadingView streamLoadingMetrics];
        __weak typeof(self)weakSelf = self;
        self.placeholderMetrics = [[StreamMetrics alloc] initWithIdentifier:@"NoMessagePlaceholderView" initializer:^(StreamMetrics * metrics) {
            [metrics setPrepareAppearing:^(StreamItem *item, id entry) {
                PlaceholderView *placeholderView = (id)item.view;
                placeholderView.textLabel.text = [NSString stringWithFormat:WLLS(@"no_chat_message"), weakSelf.wrap.name];
            }];
        }];
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    if (!self.wrap) {
        __weak typeof(self)weakSelf = self;
        run_after(0.5, ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
        return;
    }
    
    self.cachedMessageHeights = [NSMapTable strongToStrongObjectsMapTable];

    self.messageFont = [UIFont preferredDefaultFontWithPreset:WLFontPresetSmall];
    self.nameFont = [UIFont preferredDefaultLightFontWithPreset:WLFontPresetSmaller];
    self.timeFont = [UIFont preferredDefaultLightFontWithPreset:WLFontPresetSmaller];
    
    __weak typeof(self)weakSelf = self;
    
    self.unreadMessagesMetrics.finalizeAppearing = self.dateMetrics.finalizeAppearing = ^(StreamItem *item, WLMessage *message) {
        if (message.unread && weakSelf.view.superview && ![weakSelf.chat.readMessages containsObject:message]) {
            [weakSelf.chat.readMessages addObject:message];
        }
    };
    
    self.myMessageMetrics.finalizeAppearing = self.messageMetrics.finalizeAppearing = ^(StreamItem *item, WLMessage *message) {
        if (message.unread && weakSelf.view.superview && ![weakSelf.chat.readMessages containsObject:message]) {
            [weakSelf.chat.readMessages addObject:message];
        }
    };
    
    self.messageMetrics.prepareAppearing = ^(StreamItem *item, WLMessage *message) {
        [(WLMessageCell *)item.view setShowName:[weakSelf.chat.messagesWithName containsObject:message]];
    };
    
    [self.loadingViewMetrics setHiddenAt:^BOOL(StreamPosition *position, StreamMetrics *metrics) {
        return weakSelf.chat.completed;
    }];
    
    [self.loadingViewMetrics setFinalizeAppearing:^(StreamItem *item, id entry) {
        WLStreamLoadingView *loadingView = (id)item.view;
        if (weakSelf.chat.wrap) {
            loadingView.error = NO;
            [weakSelf appendMessages:^{
            } failure:^(NSError *error) {
                [error showIgnoringNetworkError];
                loadingView.error = YES;
            }];
        }
    }];
    
    WLMaxTextViewWidth = WLConstants.screenWidth - WLLeadingBubbleIndent - 2*WLMessageHorizontalInset - WLTrailingBubbleIndent;
    
    self.messageMetrics.sizeAt = self.myMessageMetrics.sizeAt = ^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
        WLMessage *message = [weakSelf.chat.entries tryAt:position.index];
        return [weakSelf heightOfMessageCell:message];
    };
    
    self.messageMetrics.insetsAt = self.myMessageMetrics.insetsAt = ^CGRect(StreamPosition *position, StreamMetrics *metrics) {
        WLMessage *message = [weakSelf.chat.entries tryAt:position.index];
        return [weakSelf.chat.groupMessages containsObject:message] ? CGRectMake(0, WLMessageGroupSpacing, 0, 0) : CGRectZero;
        [weakSelf.streamView layoutIfNeeded];
    };
	
	self.composeBar.placeholder = WLLS(@"message_placeholder");
    self.chat = [WLChat chatWithWrap:self.wrap];
    self.chat.delegate = self;

    if (self.wrap.messages.nonempty) {
        [self refreshMessages:^{
        } failure:^(NSError *error) {
            [error showIgnoringNetworkError];
        }];
    }
    
    [[WLMessage notifier] addReceiver:self];
    [[WLFontPresetter presetter] addReceiver:self];
    
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
    [self.chat.readMessages all:^(WLMessage *message) {
        [message markAsRead];
    }];
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

- (void)keyboardWillShow:(WLKeyboard *)keyboard {
    [super keyboardWillShow:keyboard];
    self.refresher.enabled = NO;
    [self.streamView setMaximumContentOffsetAnimated:NO];
}

- (void)keyboardWillHide:(WLKeyboard *)keyboard {
    [super keyboardWillHide:keyboard];
    self.refresher.enabled = YES;
}

- (void)insertMessage:(WLMessage*)message {
    
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
            if (!streamView.scrollable || streamView.contentOffset.y < streamView.maximumContentOffset.y) {
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

- (void)refreshMessages:(WLRefresher*)sender {
    [self refreshMessages:^{
        [sender setRefreshing:NO animated:YES];
    } failure:^(NSError *error) {
        [error showIgnoringNetworkError];
        [sender setRefreshing:NO animated:YES];
    }];
}

- (void)refreshMessages:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    WLMessage* message = [self.chat.entries lastObject];
    if (!message) {
        [self loadMessages:success failure:failure];
        return;
    }
    [self.wrap messagesNewer:message.createdAt success:^(NSSet *messages) {
        if (!weakSelf.wrap.messages.nonempty) weakSelf.chat.completed = YES;
        [weakSelf.chat addEntries:messages];
        if (success) success();
    } failure:failure];
}

- (void)loadMessages:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [self.wrap messages:^(NSSet *messages) {
        weakSelf.chat.completed = messages.count < WLSession.pageSize;
		[weakSelf.chat resetEntries:messages];
        if (success) success();
    } failure:failure];
}

- (void)appendMessages:(WLBlock)success failure:(WLFailureBlock)failure {
	if (self.operation) return;
	__weak typeof(self)weakSelf = self;
    WLMessage* olderMessage = [self.chat.entries firstObject];
    WLMessage* newerMessage = [self.chat.entries lastObject];
    if (!olderMessage) {
        [self loadMessages:success failure:failure];
        return;
    }
	self.operation = [self.wrap messagesOlder:olderMessage.createdAt newer:newerMessage.createdAt success:^(NSSet *messages) {
		weakSelf.chat.completed = messages.count < WLSession.pageSize;
        [weakSelf.chat addEntries:messages];
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

- (void)paginatedSetDidComplete:(WLPaginatedSet *)group {
    [self reloadData];
}

- (void)updateTypingView:(WLChat*)chat {
    if (chat.typingUsers.nonempty) {
        NSString *typingNames = chat.typingNames;
        self.typingUserNamesTextField.text = typingNames;
        self.typingUserAvatarView.hidden = self.typingUserNamesTextField.hidden = NO;
        WLUser *user = chat.typingUsers.firstObject;
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
    [self.typingView layoutIfNeeded];
}

- (void)chat:(WLChat*)chat didBeginTyping:(WLUser *)user {
    [self updateTypingView:chat];
    [self setTypingViewHidden:NO];
}
    
- (void)chat:(WLChat*)chat didEndTyping:(WLUser *)user {
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

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier didAddEntry:(WLMessage *)message {
    [self insertMessage:message];
}

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLEntry *)entry {
    [self reloadData];
}

- (void)notifier:(WLEntryNotifier *)notifier didDeleteEntry:(WLEntry *)entry {
    [self.chat removeEntry:entry];
    if (entry.unread) {
        [self updateBadge];
    }
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
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
        UIEdgeInsets insets = self.streamView.contentInset;
        if (hidden) {
            insets.bottom = 0;
            [self.typingView topPushWithDuration:0.2 delegate:nil];
        } else {
            insets.bottom = self.typingView.height;
            [self.typingView bottomPushWithDuration:0.2 delegate:nil];
        }
        self.streamView.contentInset = insets;
        self.typingView.hidden = hidden;
    }
}

#pragma mark - WLComposeBarDelegate

- (void)sendMessageWithText:(NSString*)text {
    if (self.wrap.valid) {
        __weak typeof(self)weakSelf = self;
        [self.wrap uploadMessage:text success:^(WLMessage *message) {
            [weakSelf.streamView setMaximumContentOffsetAnimated:YES];
        } failure:^(NSError *error) {
        }];
        [WLSoundPlayer playSound:WLSound_s04];
        [self.streamView setMaximumContentOffsetAnimated:YES];
        [self.chat.readMessages all:^(WLMessage *message) {
            [message markAsRead];
        }];
    } else {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
    self.typing = NO;
	[self sendMessageWithText:text];
}

- (void)composeBarDidBeginEditing:(WLComposeBar *)composeBar {
    if (self.streamView.scrollable) {
        [self.streamView setMaximumContentOffsetAnimated:self.viewAppeared];
    }
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

- (void)streamView:(StreamView * __nonnull)streamView didLayoutItem:(StreamItem * __nonnull)item {
    item.entry = [self.chat.entries tryAt:item.position.index];
}

- (NSArray*)streamView:(StreamView*)streamView metricsAt:(StreamPosition*)position {
    NSMutableArray *metrics = [NSMutableArray array];
    WLMessage *message = [self.chat.entries tryAt:position.index];
    if ([self.chat.unreadMessages firstObject] == message) {
        [metrics addObject:self.unreadMessagesMetrics];
    }
    if ([self.chat.messagesWithDay containsObject:message]) {
        [metrics addObject:self.dateMetrics];
    }
    if (message.contributedByCurrentUser) {
        [metrics addObject:self.myMessageMetrics];
    } else {
        [metrics addObject:self.messageMetrics];
    }
    return metrics;
}

- (NSArray *)streamViewHeaderMetrics:(StreamView * __nonnull)streamView {
    return @[self.loadingViewMetrics];
}

- (void)streamViewDidChangeContentSize:(StreamView * __nonnull)streamView oldContentSize:(CGSize)oldContentSize {
    if (streamView.scrollable) {
        if (self.dragged) {
            CGPoint offset = streamView.contentOffset;
            offset.y += streamView.contentSize.height - oldContentSize.height;
            streamView.contentOffset = offset;
        } else {
            [streamView setMaximumContentOffsetAnimated:NO];
        }
    }
}

- (StreamMetrics *)streamViewPlaceholderMetrics:(StreamView *)streamView {
    return self.placeholderMetrics;
}

- (CGFloat)heightOfMessageCell:(WLMessage *)message {
    NSNumber *cachedHeight = [self.cachedMessageHeights objectForKey:message];
    if (cachedHeight) {
        return [cachedHeight floatValue];
    }
    if (!self.messageFont) {
        return 0;
    }
    BOOL containsName = [self.chat.messagesWithName containsObject:message];
    CGFloat calculateWight = message.contributedByCurrentUser ? WLConstants.screenWidth - WLLeadingBubbleIndent - WLTrailingBubbleIndent : WLMaxTextViewWidth;
    CGFloat commentHeight = [message.text heightWithFont:self.messageFont width:calculateWight];
    CGFloat topInset = containsName ? self.nameFont.lineHeight + WLMessageVerticalInset : 0;
    CGFloat bottomInset = self.timeFont.lineHeight + WLMessageVerticalInset;
    commentHeight = topInset + commentHeight + bottomInset;
    commentHeight = MAX (containsName ? WLMessageWithNameMinimumCellHeight : WLMessageWithoutNameMinimumCellHeight, commentHeight + WLMessageVerticalInset);
    [self.cachedMessageHeights setObject:@(commentHeight) forKey:message];
    return commentHeight;
}

- (void)refreshUnreadMessagesAfterDragging {
    if (self.chat.unreadMessages.count == 0) {
        [self updateBadge];
        return;
    }
    
    [self.chat.readMessages all:^(WLMessage *message) {
        [message markAsRead];
    }];
    
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

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self.cachedMessageHeights removeAllObjects];
    self.messageFont = [self.messageFont preferredFontWithPreset:WLFontPresetSmall];
    self.nameFont = [self.nameFont preferredFontWithPreset:WLFontPresetSmaller];
    self.timeFont = [self.timeFont preferredFontWithPreset:WLFontPresetSmaller];
    [self reloadData];
}

@end
