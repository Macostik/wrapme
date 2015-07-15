//
//  WLChatViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSDate+Additions.h"
#import "NSObject+NibAdditions.h"
#import "UIFont+CustomFonts.h"
#import "UIScrollView+Additions.h"
#import "UIView+AnimationHelper.h"
#import "WLChat.h"
#import "WLChatViewController.h"
#import "WLCollectionViewFlowLayout.h"
#import "WLComposeBar.h"
#import "WLKeyboard.h"
#import "WLLoadingView.h"
#import "WLMessageCell.h"
#import "WLRefresher.h"
#import "WLSignificantTimeBroadcaster.h"
#import "WLSoundPlayer.h"
#import "WLTypingView.h"
#import "WLFontPresetter.h"
#import "WLMessageDateView.h"
#import "WLWrapViewController.h"
#import "WLEntryPresenter.h"
#import "WLToast.h"
#import "WLCollectionView.h"
#import "WLChatLayout.h"
#import "WLBadgeLabel.h"
#import "WLMessagesCounter.h"

CGFloat WLMaxTextViewWidth;

@interface WLChatViewController () <UICollectionViewDataSource, UICollectionViewDelegate, WLComposeBarDelegate, UICollectionViewDelegateFlowLayout, WLKeyboardBroadcastReceiver, WLEntryNotifyReceiver, WLChatDelegate, WLChatCollectionViewLayoutDelegate>

@property (weak, nonatomic) IBOutlet WLCollectionView *collectionView;

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@property (nonatomic, readonly) WLChatLayout* layout;

@property (weak, nonatomic) id operation;

@property (nonatomic) BOOL typing;

@property (strong, nonatomic) WLChat *chat;

@property (strong, nonatomic) UIFont* nameFont;

@property (strong, nonatomic) UIFont* messageFont;

@property (strong, nonatomic) UIFont* timeFont;

@property (weak, nonatomic) WLRefresher* refresher;

@property (strong, nonatomic) NSMapTable* cachedMessageHeights;

@property (weak, nonatomic) WLTypingView *typingView;

@end

@implementation WLChatViewController

@dynamic delegate;

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    self.collectionView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (WLCollectionViewFlowLayout *)layout {
	return (WLCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
}

- (void)reloadChatAfterApplicationBecameActive {
    __weak typeof(self)weakSelf = self;
    [self.chat resetEntries:self.wrap.messages];
    [self.chat refreshUnreadMessages:^(NSOrderedSet *orderedSet) {
        [weakSelf scrollToLastUnreadMessage];
        [weakSelf notifyOnChangeUnreadMessagesCount:orderedSet.count];
    } failure:^(NSError *error) {
    }];
}

- (BOOL)geometryFlipped {
    return YES;
}

- (void)viewDidLoad {
    
    if (!self.wrap) {
        __weak typeof(self)weakSelf = self;
        run_after(0.5, ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
        return;
    }
    
    self.cachedMessageHeights = [NSMapTable strongToStrongObjectsMapTable];
    
    self.messageFont = [UIFont preferredFontWithName:WLFontOpenSansRegular preset:WLFontPresetNormal];
    self.nameFont = [UIFont preferredFontWithName:WLFontOpenSansLight preset:WLFontPresetNormal];
    self.timeFont = [UIFont preferredFontWithName:WLFontOpenSansLight preset:WLFontPresetSmall];
    
    [self.collectionView registerNib:[WLLoadingView nib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WLLoadingViewIdentifier];
    [self.collectionView registerNib:[WLTypingView nib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"WLTypingViewCell"];
    [self.collectionView registerNib:[WLMessageDateView nib] forSupplementaryViewOfKind:@"date" withReuseIdentifier:@"WLMessageDateView"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"WLUnreadMessagesView" bundle:nil] forSupplementaryViewOfKind:@"unreadMessagesView" withReuseIdentifier:@"unreadMessagesView"];
    [self.layout registerItemFooterSupplementaryViewKind:@"date"];
    [self.layout registerItemFooterSupplementaryViewKind:@"unreadMessagesView"];
    self.collectionView.placeholderText = [NSString stringWithFormat:WLLS(@"no_chat_message"), self.wrap.name];
    
	[super viewDidLoad];
    
    UICollectionView *collectionView = self.collectionView;
    
    self.refresher = [WLRefresher refresher:collectionView target:self action:@selector(refreshMessages:) style:WLRefresherStyleOrange];
    
    collectionView.contentOffset = CGPointMake(0, -self.composeBar.height);
    
    collectionView.layer.geometryFlipped = [self geometryFlipped];
    
    WLMaxTextViewWidth = WLConstants.screenWidth - WLAvatarWidth - 2*WLMessageHorizontalInset - WLAvatarLeading;
	
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
    [[WLSignificantTimeBroadcaster broadcaster] addReceiver:self];
    [[WLFontPresetter presetter] addReceiver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadChatAfterApplicationBecameActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __weak typeof(self)weakSelf = self;
    [[WLMessagesCounter instance] update:nil];
    [self.chat refreshUnreadMessages:^(NSOrderedSet *unreadMessages) {
        [weakSelf scrollToLastUnreadMessage];
        [weakSelf notifyOnChangeUnreadMessagesCount:unreadMessages.count];
    } failure:^(NSError *error) {
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[WLMessagesCounter instance] update:nil];
    [self refreshUnreadMessagesAndNotifyDelegate];
}

- (void)refreshUnreadMessagesAndNotifyDelegate {
    __weak typeof(self)weakSelf = self;
    [self.chat refreshUnreadMessages:^(NSOrderedSet *orderedSet) {
        [weakSelf reloadDataSynchronously:NO];
        [weakSelf notifyOnChangeUnreadMessagesCount:orderedSet.count];
    } failure:^(NSError *error) {
    }];
}

- (void)scrollToLastUnreadMessage {
    self.layout.scrollToUnreadMessages = YES;
    [self reloadDataSynchronously:NO];
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
        
        UICollectionView *collectionView = weakSelf.collectionView;
        
        if ([weakSelf.chat.entries containsObject:message]) {
            
            [operation finish];
            
        } else if (!collectionView.scrollable) {
            
            [weakSelf.chat addEntry:message];
            [operation finish];
            
        } else if (collectionView.contentOffset.y > collectionView.minimumContentOffset.y || !chatVisible) {
            
            CGFloat offset = collectionView.contentOffset.y;
            CGFloat contentHeight = collectionView.contentSize.height;
            [weakSelf.chat addEntry:message];
            
            if(message.unread) {
                [weakSelf.chat refreshUnreadMessages:^(NSOrderedSet *orderedSet) {
                    [weakSelf notifyOnChangeUnreadMessagesCount:orderedSet.count];
                } failure:^(NSError *error) {
                }];
            }
            
            [weakSelf.collectionView reloadData];
            [collectionView layoutIfNeeded];
            offset += collectionView.contentSize.height - contentHeight;
            [collectionView trySetContentOffset:CGPointMake(0, offset) animated:NO];
            [operation finish];
            
        } else {
            
            [weakSelf.chat addEntry:message];
            [weakSelf.collectionView reloadData];
            [collectionView layoutIfNeeded];
            collectionView.contentOffset = CGPointOffset(collectionView.minimumContentOffset, 0, [weakSelf heightOfMessageCell:message]);
            [collectionView setMinimumContentOffsetAnimated:YES];
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
        weakSelf.chat.completed = messages.count < WLPageSize;
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
		weakSelf.chat.completed = messages.count < WLPageSize;
        [weakSelf.chat addEntries:messages];
        if (success) success();
	} failure:failure];
}

#pragma mark - WLChatDelegate

- (void)chatDidChangeMessagesWithName:(WLChat *)chat {
    [self.cachedMessageHeights removeAllObjects];
}

- (void)paginatedSetChanged:(WLPaginatedSet *)group {
    [self reloadDataSynchronously:NO];
}

- (void)paginatedSetCompleted:(WLPaginatedSet *)group {
    [self reloadDataSynchronously:NO];
}

- (BOOL)isTypingViewHidden {
    return self.typingView.superview == nil || self.typingView.hidden;
}

- (void)chat:(WLChat*)chat didBeginTyping:(WLUser *)user {
    __weak __typeof(self)weakSelf = self;
    runUnaryQueuedOperation(@"wl_chat_insertion_queue", ^(WLOperation *operation) {
        UICollectionView *cv = weakSelf.collectionView;
        if ([weakSelf isTypingViewHidden] && CGPointEqualToPoint(cv.contentOffset, cv.minimumContentOffset)) {
            [cv reloadData];
            [cv layoutIfNeeded];
            cv.contentOffset = CGPointOffset(weakSelf.collectionView.minimumContentOffset, 0, [weakSelf heightOfTypingCell:chat]);
            [cv setMinimumContentOffsetAnimated:YES];
            run_after(1.0, ^{
                [operation finish];
            });
        } else {
            [cv reloadData];
            [operation finish];
        }
    });
}
    
- (void)chat:(WLChat*)chat didEndTyping:(WLUser *)user {
    __weak __typeof(self)weakSelf = self;
    runUnaryQueuedOperation(@"wl_chat_insertion_queue", ^(WLOperation *operation) {
        UICollectionView *cv = weakSelf.collectionView;
        CGPoint minimumContentOffset = cv.minimumContentOffset;
        if (![weakSelf isTypingViewHidden] && CGPointEqualToPoint(cv.contentOffset, minimumContentOffset) && user.valid) {
            [cv setContentOffset:CGPointOffset(minimumContentOffset, 0, [weakSelf heightOfTypingCell:chat]) animated:YES];
            run_after(1.0, ^{
                [cv reloadData];
                cv.contentOffset = weakSelf.collectionView.minimumContentOffset;
                [operation finish];
            });
        } else {
            [cv reloadData];
            [operation finish];
        }
    });
}

- (void)reloadDataSynchronously:(BOOL)synchronously {
    __weak typeof(self)weakSelf = self;
    runUnaryQueuedOperation(@"wl_chat_insertion_queue", ^(WLOperation *operation) {
        [weakSelf.collectionView reloadData];
        if (synchronously) [weakSelf.collectionView layoutIfNeeded];
        [operation finish];
    });
}

- (void)notifyOnChangeUnreadMessagesCount:(NSUInteger)count {
    self.badge.intValue = count;
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
        __weak typeof(self)weakSelf = self;
        [self.chat refreshUnreadMessages:^(NSOrderedSet *orderedSet) {
            [weakSelf notifyOnChangeUnreadMessagesCount:orderedSet.count];
        } failure:^(NSError *error) {
        }];
    }
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return self.wrap == entry.containingEntry;
}

#pragma mark - WlSignificantTimeBroadcasterReceiver

- (void)broadcaster:(WLSignificantTimeBroadcaster *)broadcaster didChangeSignificantTime:(id)object {
    [self.chat resetEntries:[self.wrap messages]];
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
            [weakSelf.collectionView setMinimumContentOffsetAnimated:YES];
        } failure:^(NSError *error) {
        }];
        [WLSoundPlayer playSound:WLSound_s04];
        [self.collectionView setMinimumContentOffsetAnimated:YES];
    } else {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
    [self setTyping:NO sendMessage:YES];
	[self sendMessageWithText:text];
}

- (void)composeBarDidBeginEditing:(WLComposeBar *)composeBar {
    if (self.collectionView.scrollable) {
        [self.collectionView setMinimumContentOffsetAnimated:self.viewAppeared];
    }
}

- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar *)composeBar {
	return NO;
}

- (void)setTyping:(BOOL)typing {
    [self setTyping:typing sendMessage:NO];
}

- (void)setTyping:(BOOL)typing sendMessage:(BOOL)sendMessage {
    if (_typing != typing) {
        _typing = typing;
        [self.chat sendTyping:typing sendMessage:sendMessage];
    }
}

- (void)composeBarDidChangeText:(WLComposeBar*)composeBar {
    self.typing = composeBar.text.nonempty;
}

- (void)composeBarDidChangeHeight:(WLComposeBar *)composeBar {
    [self.collectionView layoutIfNeeded];
    [self.collectionView setMinimumContentOffsetAnimated:YES];
}

#pragma mark - UICollectionViewDataSource

- (void)setBackgroundColorForView:(UIView*)view atIndexPath:(NSIndexPath*)indexPath {
    if (self.layout.unreadMessagesViewIndexPath) {
        view.backgroundColor = indexPath.item <= self.layout.unreadMessagesViewIndexPath.item ? [UIColor WL_grayLightest] : [UIColor whiteColor];
    } else {
        view.backgroundColor = [UIColor whiteColor];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        return 0;
    }
    return [self.chat.entries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLMessage* message = [self.chat.entries tryAt:indexPath.item];
    NSString *cellIdentifier = cellIdentifier = message.contributedByCurrentUser ? WLMyMessageCellIdentifier : WLMessageCellIdentifier;
    WLMessageCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [cell setShowName:[self.chat.messagesWithName containsObject:message]];
    cell.entry = message;
    cell.layer.geometryFlipped = [self geometryFlipped];
    
    if (message.unread && self.view.superview) {
        message.unread = NO;
    }
    
    [self setBackgroundColorForView:cell atIndexPath:indexPath];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *supplementaryView = nil;
    if ([kind isEqualToString:@"date"]) {
        WLMessageDateView* view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLMessageDateView" forIndexPath:indexPath];
        view.message = [self.chat.entries tryAt:indexPath.item];
        supplementaryView = view;
        [self setBackgroundColorForView:view atIndexPath:indexPath];
    } else if ([kind isEqualToString:@"unreadMessagesView"]) {
        supplementaryView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"unreadMessagesView" forIndexPath:indexPath];
        supplementaryView.backgroundColor = [UIColor WL_grayLightest];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
         WLLoadingView *loadingView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:WLLoadingViewIdentifier forIndexPath:indexPath];
        if (self.chat.wrap) {
            loadingView.error = NO;
            [self appendMessages:^{
            } failure:^(NSError *error) {
                [error showIgnoringNetworkError];
                loadingView.error = YES;
            }];
        }
        supplementaryView = loadingView;
    } else {
        WLTypingView *typingView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLTypingViewCell" forIndexPath:indexPath];
        typingView.chat = self.chat;
        supplementaryView = typingView;
        self.typingView = typingView;
        [self setBackgroundColorForView:typingView atIndexPath:indexPath];
    }
    supplementaryView.layer.geometryFlipped = [self geometryFlipped];
    return supplementaryView;
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
    return MAX(WLTypingViewMinHeight, [chat.typingNames heightWithFont:[UIFont preferredFontWithName:WLFontOpenSansRegular
                                                                                              preset:WLFontPresetSmaller]
                                                                 width:WLMaxTextViewWidth] + WLTypingViewTopIndent);
}

- (CGSize)collectionView:(UICollectionView *)collectionView sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLMessage *message = [self.chat.entries tryAt:indexPath.item];
    return CGSizeMake(collectionView.width, [self heightOfMessageCell:message]);
}

- (CGSize)collectionView:(UICollectionView *)collectionView sizeForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:@"date"]) {
        WLMessage *message = [self.chat.entries tryAt:indexPath.item];
        return [self.chat.messagesWithDay containsObject:message] ? CGSizeMake(collectionView.width, WLMessageDayLabelHeight) : CGSizeZero;
    } else if ([kind isEqualToString:@"unreadMessagesView"]) {
        WLMessage *message = [self.chat.entries tryAt:indexPath.item];
        BOOL showUnreadMessagesView = [self.chat showUnreadMessagesViewForMessgae:message];
        return showUnreadMessagesView ? CGSizeMake(collectionView.width, WLMessageDayLabelHeight) : CGSizeZero;
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        if (self.chat.completed) return CGSizeZero;
        return CGSizeMake(collectionView.width, WLLoadingViewDefaultSize);
    } else {
        if (!self.chat.showTypingView) return CGSizeZero;
        return CGSizeMake(collectionView.width, [self heightOfTypingCell:self.chat]);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView bottomSpacingForItemAtIndexPath:(NSIndexPath *)indexPath {
    return 0;
    WLMessage *message = [self.chat.entries tryAt:indexPath.item];
    if ([self.chat.messagesWithDay containsObject:message]) {
        return 0;
    } else if ([self.chat.messagesWithName containsObject:message]) {
        return [self.chat showUnreadMessagesViewForMessgae:message] ? 0 : WLMessageGroupSpacing;
    } else {
        return [self.chat showUnreadMessagesViewForMessgae:message] ? 0 : 3;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView applyContentSizeInsetForAttributes:(UICollectionViewLayoutAttributes *)attributes {
    return ![attributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader];
}

- (void)refreshUnreadMessagesAfterDragging {
    if (self.chat.unreadMessagesCount == 0) {
        return;
    }
    
    [[WLMessagesCounter instance] update:nil];
    
    __weak typeof(self)weakSelf = self;
    [self.chat refreshUnreadMessages:^(NSOrderedSet *orderedSet) {
        [weakSelf reloadDataSynchronously:NO];
        [weakSelf notifyOnChangeUnreadMessagesCount:orderedSet.count];
    } failure:^(NSError *error) {
    }];
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
