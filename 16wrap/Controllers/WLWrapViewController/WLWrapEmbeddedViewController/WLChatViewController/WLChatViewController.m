//
//  WLChatViewController.m
//  moji
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
#import "WLLoadingView.h"
#import "WLMessageCell.h"
#import "WLRefresher.h"
#import "WLSoundPlayer.h"
#import "WLTypingView.h"
#import "WLFontPresetter.h"
#import "WLMessageDateView.h"
#import "WLWrapViewController.h"
#import "WLEntryPresenter.h"
#import "WLToast.h"
#import "WLCollectionView.h"
#import "WLBadgeLabel.h"
#import "WLMessagesCounter.h"
#import "StreamView.h"

CGFloat WLMaxTextViewWidth;

@interface WLChatViewController () <StreamViewDelegate, WLComposeBarDelegate, WLKeyboardBroadcastReceiver, WLEntryNotifyReceiver, WLChatDelegate>

@property (weak, nonatomic) IBOutlet StreamView *streamView;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@property (weak, nonatomic) id operation;

@property (nonatomic) BOOL typing;

@property (strong, nonatomic) WLChat *chat;

@property (strong, nonatomic) UIFont* nameFont;

@property (strong, nonatomic) UIFont* messageFont;

@property (strong, nonatomic) UIFont* timeFont;

@property (weak, nonatomic) WLRefresher* refresher;

@property (strong, nonatomic) NSMapTable* cachedMessageHeights;

@property (weak, nonatomic) WLTypingView *typingView;
@property (strong, nonatomic) IBOutlet StreamMetrics *messageMetrics;
@property (strong, nonatomic) IBOutlet StreamMetrics *myMessageMetrics;
@property (strong, nonatomic) IBOutlet StreamMetrics *dateMetrics;
@property (strong, nonatomic) IBOutlet StreamMetrics *unreadMessagesMetrics;
@property (strong, nonatomic) IBOutlet StreamMetrics *typingViewMetrics;
@property (strong, nonatomic) IBOutlet StreamMetrics *loadingViewMetrics;

@end

@implementation WLChatViewController

@dynamic delegate;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)reloadChatAfterApplicationBecameActive {
    [self.chat resetEntries:self.wrap.messages];
    [self scrollToLastUnreadMessage];
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

    self.messageFont = [UIFont preferredDefaultFontWithPreset:WLFontPresetNormal];
    self.nameFont = [UIFont preferredDefaultLightFontWithPreset:WLFontPresetNormal];
    self.timeFont = [UIFont preferredDefaultLightFontWithPreset:WLFontPresetSmall];
    
#warning implement placeholder
//    self.collectionView.placeholderText = [NSString stringWithFormat:WLLS(@"no_chat_message"), self.wrap.name];
    
    __weak StreamView *streamView = self.streamView;
    
    __weak typeof(self)weakSelf = self;
    
    self.refresher = [WLRefresher refresher:streamView target:self action:@selector(refreshMessages:) style:WLRefresherStyleOrange];
    
    streamView.layer.geometryFlipped = YES;
    
    self.typingViewMetrics.finalizeAppearingBlock = self.unreadMessagesMetrics.finalizeAppearingBlock = self.dateMetrics.finalizeAppearingBlock = ^(StreamItem *item, WLMessage *message) {
        [[item.view layer] setGeometryFlipped:streamView.layer.geometryFlipped];
        item.view.backgroundColor = [weakSelf backgroundColorForMessage:message];
    };
    
    self.myMessageMetrics.prepareAppearingBlock = self.messageMetrics.prepareAppearingBlock = ^(StreamItem *item, WLMessage *message) {
        [(WLMessageCell*)item.view setShowName:[weakSelf.chat.messagesWithName containsObject:message]];
    };
    
    self.myMessageMetrics.finalizeAppearingBlock = self.messageMetrics.finalizeAppearingBlock = ^(StreamItem *item, WLMessage *message) {
        [[item.view layer] setGeometryFlipped:streamView.layer.geometryFlipped];
        if (message.unread && weakSelf.view.superview && ![weakSelf.chat.readMessages containsObject:message]) {
            [weakSelf.chat.readMessages addObject:message];
        }
        item.view.backgroundColor = [weakSelf backgroundColorForMessage:message];
    };
    
    [self.loadingViewMetrics setHiddenBlock:^BOOL(StreamIndex *index, StreamMetrics *metrics) {
        return weakSelf.chat.completed;
    }];
    
    [self.loadingViewMetrics setFinalizeAppearingBlock:^(StreamItem *item, id entry) {
        WLLoadingView *loadingView = (id)item.view;
        if (weakSelf.chat.wrap) {
            loadingView.error = NO;
            [weakSelf appendMessages:^{
            } failure:^(NSError *error) {
                [error showIgnoringNetworkError];
                loadingView.error = YES;
            }];
        }
    }];
    
    [self.typingViewMetrics setSizeBlock:^CGFloat(StreamIndex *index, StreamMetrics *metrics) {
        return [weakSelf heightOfTypingCell:weakSelf.chat];
    }];
    
    [self.typingViewMetrics setFinalizeAppearingBlock:^(StreamItem *item, id entry) {
        [(WLTypingView*)item.view updateWithChat:weakSelf.chat];
    }];
    
    WLMaxTextViewWidth = WLConstants.screenWidth - WLAvatarWidth - 2*WLMessageHorizontalInset - WLAvatarLeading;
    
    self.messageMetrics.sizeBlock = self.myMessageMetrics.sizeBlock = ^CGFloat(StreamIndex *index, StreamMetrics *metrics) {
        WLMessage *message = [weakSelf.chat.entries tryAt:index.item];
        return [weakSelf heightOfMessageCell:message];
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
    
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[WLMessagesCounter instance] update:nil];
    [self.chat sort];
    [self scrollToLastUnreadMessage];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadChatAfterApplicationBecameActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    if (self.showKeyboard) {
        [self.composeBar becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.chat.readMessages all:^(WLMessage *message) {
        [message markAsRead];
    }];
    [[WLMessagesCounter instance] update:nil];
    [self.chat sort];
    [self.chat.unreadMessages minusSet:[self.chat.readMessages set]];
    [self updateBadge];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)scrollToLastUnreadMessage {
#warning implement scrolling to unread message
//    self.layout.scrollToUnreadMessages = YES;
    [self reloadDataSynchronously:NO];
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
}

- (void)keyboardWillHide:(WLKeyboard *)keyboard {
    [super keyboardWillHide:keyboard];
    self.refresher.enabled = YES;
}

- (void)insertMessage:(WLMessage*)message {
    
    if (!self.view.superview) {
        [self.chat addEntry:message];
        return;
    }
    
    UIApplicationState applicationState = [UIApplication sharedApplication].applicationState;
    if (applicationState == UIApplicationStateBackground) {
        return;
    }
    BOOL chatVisible = applicationState == UIApplicationStateActive;
    __weak typeof(self)weakSelf = self;
    runUnaryQueuedOperation(@"wl_chat_insertion_queue", ^(WLOperation *operation) {
        
        StreamView *streamView = weakSelf.streamView;
        
        if ([weakSelf.chat.entries containsObject:message]) {
            
            [operation finish];
            
        } else if (!streamView.scrollable) {
            
            [weakSelf.chat addEntry:message];
            [operation finish];
            
        } else if (streamView.contentOffset.y > streamView.minimumContentOffset.y || !chatVisible) {
            
            CGFloat offset = streamView.contentOffset.y;
            CGFloat contentHeight = streamView.contentSize.height;
            [weakSelf.chat addEntry:message];
            [streamView reload];
            [streamView layoutIfNeeded];
            offset += streamView.contentSize.height - contentHeight;
            [streamView trySetContentOffset:CGPointMake(0, offset) animated:NO];
            [operation finish];
            
        } else {
            
            [weakSelf.chat addEntry:message];
            
            if (streamView.height/2 < [weakSelf heightOfMessageCell:message] &&
                [self.chat.unreadMessages count] == 1) {
//                self.layout.scrollToUnreadMessages = YES;
            } else {
                [streamView reload];
                [streamView layoutIfNeeded];
                streamView.contentOffset = CGPointOffset(streamView.minimumContentOffset, 0, [weakSelf heightOfMessageCell:message]);
                [streamView setMinimumContentOffsetAnimated:YES];
            }
            
            run_after(0.5, ^{
                [operation finish];
            });
            
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
    WLMessage* message = [self.chat.entries firstObject];
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
        weakSelf.chat.completed = messages.count < WLConstants.pageSize;
		[weakSelf.chat resetEntries:messages];
        if (success) success();
    } failure:failure];
}

- (void)appendMessages:(WLBlock)success failure:(WLFailureBlock)failure {
	if (self.operation) return;
	__weak typeof(self)weakSelf = self;
    WLMessage* olderMessage = [self.chat.entries lastObject];
    WLMessage* newerMessage = [self.chat.entries firstObject];
    if (!olderMessage) {
        [self loadMessages:success failure:failure];
        return;
    }
	self.operation = [self.wrap messagesOlder:olderMessage.createdAt newer:newerMessage.createdAt success:^(NSSet *messages) {
		weakSelf.chat.completed = messages.count < WLConstants.pageSize;
        [weakSelf.chat addEntries:messages];
        if (success) success();
	} failure:failure];
}

#pragma mark - WLChatDelegate

- (void)chatDidChangeMessagesWithName:(WLChat *)chat {
    [self.cachedMessageHeights removeAllObjects];
}

- (void)setDidChange:(WLPaginatedSet *)group {
    [self reloadDataSynchronously:NO];
}

- (void)paginatedSetDidComplete:(WLPaginatedSet *)group {
    [self reloadDataSynchronously:NO];
}

- (void)chat:(WLChat*)chat didBeginTyping:(WLUser *)user {
    [self reloadDataSynchronously:NO];
}
    
- (void)chat:(WLChat*)chat didEndTyping:(WLUser *)user {
    [self reloadDataSynchronously:NO];
}

- (void)reloadDataSynchronously:(BOOL)synchronously {
    __weak typeof(self)weakSelf = self;
    static BOOL reloading = NO;
    if (reloading) {
        return;
    }
    reloading = YES;
    runUnaryQueuedOperation(@"wl_chat_insertion_queue", ^(WLOperation *operation) {
        [weakSelf.streamView reload];
        [operation finish];
        reloading = NO;
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
    [self reloadDataSynchronously:NO];
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

#pragma mark - WLComposeBarDelegate

- (void)sendMessageWithText:(NSString*)text {
    if (self.wrap.valid) {
        __weak typeof(self)weakSelf = self;
        [self.wrap uploadMessage:text success:^(WLMessage *message) {
            [weakSelf.streamView setMinimumContentOffsetAnimated:YES];
        } failure:^(NSError *error) {
        }];
        [WLSoundPlayer playSound:WLSound_s04];
        [self.streamView setMinimumContentOffsetAnimated:YES];
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
        [self.streamView setMinimumContentOffsetAnimated:self.viewAppeared];
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
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground || !self.view.superview) {
        return 0;
    }
    [self updateBadge];
    return [self.chat.entries count];
}

- (id)streamView:(StreamView*)streamView entryAt:(StreamIndex*)index {
    return [self.chat.entries tryAt:index.item];
}

- (NSArray*)streamView:(StreamView*)streamView metricsAt:(StreamIndex*)index {
    NSMutableArray *metrics = [NSMutableArray array];
    WLMessage *message = [self.chat.entries tryAt:index.item];
    if (message.contributedByCurrentUser) {
        [metrics addObject:self.myMessageMetrics];
    } else {
        [metrics addObject:self.messageMetrics];
    }
    if ([self.chat.messagesWithDay containsObject:message]) {
        [metrics addObject:self.dateMetrics];
    }
    if ([self.chat.unreadMessages lastObject] == message) {
        [metrics addObject:self.unreadMessagesMetrics];
    }
    return metrics;
}

- (NSArray *)streamViewFooterMetrics:(StreamView *)streamView {
    return @[self.loadingViewMetrics];
}

- (NSArray*)streamViewHeaderMetrics:(StreamView*)streamView {
    return @[self.typingViewMetrics];
}

- (UIColor*)backgroundColorForMessage:(WLMessage*)message {
    if (self.chat.unreadMessages.nonempty) {
        NSUInteger index = [self.chat.entries indexOfObject:message];
        NSUInteger index1 = [self.chat.entries indexOfObject:[self.chat unreadMessages]];
        return index <= index1 ? WLColors.grayLightest : [UIColor whiteColor];
    } else {
        return [UIColor whiteColor];
    }
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
    CGFloat commentHeight = [message.text heightWithFont:self.messageFont width:WLMaxTextViewWidth] + WLMessageVerticalInset;
    CGFloat topInset = (containsName ? self.nameFont.lineHeight : 0);
    CGFloat bottomInset = self.timeFont.lineHeight;
    commentHeight = topInset + commentHeight + bottomInset;
    commentHeight = MAX (containsName ? WLMessageWithNameMinimumCellHeight : WLMessageWithoutNameMinimumCellHeight, commentHeight) + 4;
    [self.cachedMessageHeights setObject:@(commentHeight) forKey:message];
    return commentHeight;
}

- (CGFloat)heightOfTypingCell:(WLChat *)chat {
    if (chat.wrap.messages.nonempty || chat.typingUsers.nonempty) {
        return MAX(WLTypingViewMinHeight, [chat.typingNames heightWithFont:[UIFont preferredDefaultLightFontWithPreset:WLFontPresetSmaller]
                                                                     width:WLMaxTextViewWidth] + WLTypingViewTopIndent);
    } else {
        return 0;
    }
}

#warning implement adjusting content inset

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
    if (!decelerate) {
        [self refreshUnreadMessagesAfterDragging];
    }
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self.cachedMessageHeights removeAllObjects];
    self.messageFont = [self.messageFont preferredFontWithPreset:WLFontPresetNormal];
    self.nameFont = [self.nameFont preferredFontWithPreset:WLFontPresetNormal];
    self.timeFont = [self.timeFont preferredFontWithPreset:WLFontPresetSmall];
    [self reloadDataSynchronously:NO];
}

@end
