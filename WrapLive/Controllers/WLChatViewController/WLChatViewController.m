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
#import "WLTypingViewCell.h"
#import "WLFontPresetter.h"
#import "WLMessageDateView.h"
#import "WLMessageGroupCell.h"
#import "InversedFlowLayout.h"

CGFloat WLMaxTextViewWidth;

@interface WLChatViewController () <UICollectionViewDataSource, UICollectionViewDelegate, WLComposeBarDelegate, UICollectionViewDelegateFlowLayout, WLKeyboardBroadcastReceiver, WLEntryNotifyReceiver, WLChatDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@property (nonatomic, readonly) InversedFlowLayout* layout;

@property (weak, nonatomic) id operation;

@property (nonatomic) BOOL typing;

@property (strong, nonatomic) WLChat *chat;

@property (strong, nonatomic) UIFont* messageFont;

@property (weak, nonatomic) WLRefresher* refresher;

@property (nonatomic) BOOL animating;

@end

@implementation WLChatViewController

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    self.collectionView = nil;
}

- (WLCollectionViewFlowLayout *)layout {
	return (WLCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
}

- (void)viewDidLoad {
    
    [self.collectionView registerNib:[WLLoadingView nib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WLLoadingViewIdentifier];
    [self.collectionView registerNib:[WLTypingViewCell nib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"WLTypingViewCell"];
    [self.collectionView registerNib:[WLMessageDateView nib] forSupplementaryViewOfKind:@"date" withReuseIdentifier:@"WLMessageDateView"];
    [self.layout registerItemFooterSupplementaryViewKind:@"date"];
    
	[super viewDidLoad];
    
    UICollectionView *collectionView = self.collectionView;
    
    [self updateEdgeInsets:0];
    self.refresher = [WLRefresher refresher:collectionView target:self action:@selector(refreshMessages:) style:WLRefresherStyleOrange];
    
    collectionView.contentOffset = CGPointMake(0, -self.composeBar.height);
    
    collectionView.layer.geometryFlipped = YES;
    
    self.messageFont = [UIFont preferredFontWithName:WLFontOpenSansRegular preset:WLFontPresetNormal];
    
    WLMaxTextViewWidth = WLConstants.screenWidth - WLAvatarWidth - 2*WLMessageHorizontalInset - WLAvatarLeading;
    
	__weak typeof(self)weakSelf = self;
    [self.wrap fetchIfNeeded:^(id object) {
        weakSelf.titleLabel.text = [NSString stringWithFormat:WLLS(@"Chat in %@"), WLString(weakSelf.wrap.name)];
    } failure:^(NSError *error) {
    }];
	
	self.composeBar.placeholder = WLLS(@"Write your message ...");
    self.chat = [WLChat chatWithWrap:self.wrap];
    self.chat.delegate = self;

    if (self.wrap.messages.nonempty) {
        [self refreshMessages:^{
        } failure:^(NSError *error) {
            [error showIgnoringNetworkError];
        }];
    }
	
	self.backSwipeGestureEnabled = YES;
	
    [[WLMessage notifier] addReceiver:self];
    [[WLSignificantTimeBroadcaster broadcaster] addReceiver:self];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (void)updateEdgeInsets:(CGFloat)keyboardHeight {
    UICollectionView *collectionView = self.collectionView;
    UIEdgeInsets insets = UIEdgeInsetsMake(self.composeBar.height + keyboardHeight, 0, 0, 0);
    collectionView.contentInset = insets;
    insets.right = collectionView.width - 6;
    collectionView.scrollIndicatorInsets = insets;
    [self.layout invalidate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
    [self scrollToLastUnreadMessage];
   
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.wrap.messages all:^(WLMessage *message) {
        if(message.unread) message.unread = NO;
    }];
}

- (void)scrollToLastUnreadMessage {
    run_after(.05, ^{
        __weak __typeof(self)weakSelf = self;
        WLMessage *unreadMessage = [self.wrap.messages selectObject:^BOOL(WLMessage *message) {
            return [message.updatedAt isEqualToDate:weakSelf.wrap.lastUnread];
        }];
        if (unreadMessage.valid) {
            NSIndexPath *indexPathForCell = [NSIndexPath indexPathForItem:[weakSelf.chat.entries indexOfObject:unreadMessage] inSection:0];
            if (indexPathForCell.item != NSNotFound) {
                [self.collectionView scrollToItemAtIndexPath:indexPathForCell atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            }
        }
    });
}

- (void)keyboardWillShow:(WLKeyboard *)keyboard {
    [super keyboardWillShow:keyboard];
    
    [UIView performWithoutAnimation:^{
        [self updateEdgeInsets:keyboard.height];
        [self.collectionView setMinimumContentOffsetAnimated:self.viewAppeared];
    }];
    
    self.refresher.enabled = NO;
}

- (void)keyboardWillHide:(WLKeyboard *)keyboard {
    [super keyboardWillHide:keyboard];
    [UIView performWithoutAnimation:^{
        [self updateEdgeInsets:0];
    }];
    self.refresher.enabled = YES;
}

- (void)performInsertAnimation:(void (^)(WLBlock completion))animation failure:(WLFailureBlock)failure {
    if (!self.animating) {
        self.animating = YES;
        __weak typeof(self)weakSelf = self;
        [self.collectionView reloadData];
        [self.collectionView layoutIfNeeded];
        animation(^{
            weakSelf.animating = NO;
            [weakSelf reloadData];
        });
    } else {
        if (failure) failure(nil);
    }
}

- (void)insertMessage:(WLMessage*)message {
    __weak typeof(self)weakSelf = self;
    runUnaryQueuedOperation(@"wl_chat_insertion_queue", ^(WLOperation *operation) {
        if ([weakSelf.chat.entries containsObject:message]) {
            [operation finish];
            return;
        }

        BOOL applicationActive = [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
        UICollectionView *collectionView = weakSelf.collectionView;
        if (!weakSelf.animating && (collectionView.contentOffset.y > -(weakSelf.composeBar.height + [WLKeyboard keyboard].height) || !applicationActive)) {
            [weakSelf.chat addEntry:message];
            CGFloat offset = collectionView.contentOffset.y;
            CGFloat contentHeight = collectionView.contentSize.height;
            [collectionView reloadData];
            [collectionView layoutIfNeeded];
            offset += collectionView.contentSize.height - contentHeight;
            [collectionView trySetContentOffset:CGPointMake(0, offset) animated:NO];
            [operation finish];
        } else {
            [weakSelf performInsertAnimation:^(WLBlock completion) {
                
                [weakSelf.chat addEntry:message];
                [collectionView performBatchUpdates:^{
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[weakSelf.chat.entries indexOfObject:message] inSection:0];
                    [collectionView insertItemsAtIndexPaths:@[indexPath]];
//                    [collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                } completion:^(BOOL finished) {
                    completion();
                    [operation finish];
                }];
            } failure:^(NSError *error) {
                [operation finish];
            }];
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
    [self.wrap messagesNewer:message.createdAt success:^(NSOrderedSet *messages) {
        if (!weakSelf.wrap.messages.nonempty) weakSelf.chat.completed = YES;
        [weakSelf.chat addEntries:messages];
        if (success) success();
    } failure:failure];
}

- (void)loadMessages:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [self.wrap messages:^(NSOrderedSet *messages) {
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
	self.operation = [self.wrap messagesOlder:olderMessage.createdAt newer:newerMessage.createdAt success:^(NSOrderedSet *messages) {
		weakSelf.chat.completed = messages.count < WLPageSize;
        [weakSelf.chat addEntries:messages];
        if (success) success();
	} failure:failure];
}

#pragma mark - WLChatDelegate

- (void)paginatedSetChanged:(WLPaginatedSet *)group {
    [self reloadData];
}

- (void)paginatedSetCompleted:(WLPaginatedSet *)group {
    [self reloadData];
}

- (void)reloadData {
    if (!self.animating) {
        [self.collectionView reloadData];
        [self.layout invalidate];
    }
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier messageAdded:(WLMessage *)message {
    if (message.unread) message.unread = NO;
    [self insertMessage:message];
}

- (void)notifier:(WLEntryNotifier *)notifier messageDeleted:(WLMessage *)message {
    [self.chat resetEntries:[self.wrap messages]];
}

- (WLWrap *)notifierPreferredWrap:(WLEntryNotifier *)notifier {
    return self.wrap;
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
        [self storeVisitSession];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)storeVisitSession {
    NSMutableArray *arrayIndex = [[NSMutableArray alloc] initWithArray:self.collectionView.indexPathsForVisibleItems];
    if (arrayIndex.count != 0) {
        [arrayIndex sortUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
            return obj1.item < obj2.item;
        }];
        NSIndexPath *lastVisibleIndexPath = arrayIndex.lastObject;
        WLMessage * message = [self.chat.entries objectAtIndex:lastVisibleIndexPath.item];
        if (lastVisibleIndexPath.item != NSNotFound && message.valid) {
            if (!self.wrap.lastUnread || [self.wrap.lastUnread earlier:message.updatedAt]) {
                self.wrap.lastUnread = message.updatedAt;
            }
        }
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
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
    [self setTyping:NO sendMessage:YES];
	[self sendMessageWithText:text];
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
        if (typing) {
            [self.chat.typingChannel beginTyping];
        } else {
            [self.chat.typingChannel endTyping:sendMessage];
        }
    }
}

- (void)composeBarDidChangeText:(WLComposeBar*)composeBar {
    __weak __typeof(self)weakSelf = self;
    if (self.chat.typingChannel.subscribed) {
        weakSelf.typing = composeBar.text.nonempty;
    }
}

- (void)composeBarDidChangeHeight:(WLComposeBar *)composeBar {
    self.refresher.inset = composeBar.height;
    [self updateEdgeInsets:[WLKeyboard keyboard].height];
    [self.collectionView setMinimumContentOffsetAnimated:YES];
}

//#pragma mark - UICollectionViewDataSource
//
//- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
//    [self.itemsWithName removeAllIndexes];
//    [self.itemsWithDay removeAllIndexes];
//    return 3;
//}
//
//- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
//    if ([self.supplementarySections containsIndex:section]) {
//        return 0;
//    }
//    return [self.chat.entries count];
//}
//
//- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
//    WLMessage* message = [self.chat.entries tryObjectAtIndex:indexPath.item];
//    NSString *cellIdentifier = cellIdentifier = message.contributedByCurrentUser ? WLMyMessageCellIdentifier : WLMessageCellIdentifier;
//    WLMessageCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
//    [cell setShowName:[self.itemsWithName containsIndex:indexPath.item] || [self.itemsWithDay containsIndex:indexPath.item]
//              showDay:[self.itemsWithDay containsIndex:indexPath.item]];
//    cell.entry = message;
//    return cell;
//}
//
//- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
//    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
//        WLTypingViewCell* typingView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLTypingViewCell" forIndexPath:indexPath];
//        typingView.names = self.chat.typingNames;
//        return typingView;
//    } else {
//        WLLoadingView* loadingView = [WLLoadingView dequeueInCollectionView:collectionView indexPath:indexPath];
//        if (self.chat.wrap) {
//            loadingView.error = NO;
//            [self appendMessages:^{
//            } failure:^(NSError *error) {
//                [error showIgnoringNetworkError];
//            }];
//        }
//        return loadingView;
//    }
//}
//
//- (CGFloat)heightOfMessageCell:(WLMessage *)message containsName:(BOOL)containsName showDay:(BOOL)showDay {
//    CGFloat commentHeight = WLCalculateHeightString(message.text, self.messageFont, WLMaxTextViewWidth);
//    CGFloat topInset = (containsName ? WLMessageNameInset : WLMessageVerticalInset);
//    if (showDay) {
//        topInset += WLMessageDayLabelHeight;
//    } else if (containsName) {
//        topInset += WLMessageGroupSpacing;
//    }
//    CGFloat bottomInset = WLMessageNameInset;
//    commentHeight = topInset + commentHeight + bottomInset;
//    return MAX (containsName ? WLMessageWithNameMinimumCellHeight : WLMessageWithoutNameMinimumCellHeight, commentHeight);
//}
//
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
//    WLMessage *message = [self.chat.entries tryObjectAtIndex:indexPath.item];
//    WLMessage* previousMessage = [self.chat.entries tryObjectAtIndex:indexPath.item + 1];
//    BOOL showDay = previousMessage == nil || ![previousMessage.createdAt isSameDay:message.createdAt];
//    BOOL containsName = (previousMessage == nil || previousMessage.contributor != message.contributor) || showDay;
//    if (containsName) {
//        [self.itemsWithName addIndex:indexPath.item];
//    }
//    if (showDay) {
//        [self.itemsWithDay addIndex:indexPath.item];
//    }
//    return CGSizeMake(WLConstants.screenWidth, [self heightOfMessageCell:message containsName:containsName showDay:showDay]);
//}
//
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
//    if (section != WLChatLoadingSection || self.chat.completed || ![WLNetwork network].reachable) return CGSizeZero;
//    return CGSizeMake(collectionView.width, WLLoadingViewDefaultSize);
//}
//
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
//    if (section != WLChatTypingSection || !self.chat.showTypingView) return CGSizeZero;
//    return CGSizeMake(collectionView.width, MAX(WLTypingViewMinHeight, [self.chat.typingNames heightWithFont:[UIFont preferredFontWithName:WLFontOpenSansRegular preset:WLFontPresetNormal] width:WLConstants.screenWidth - 78.0f]));
//}
//
//- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
//    return 3;
//}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.chat.entries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLMessage* message = [self.chat.entries tryObjectAtIndex:indexPath.item];
    NSString *cellIdentifier = cellIdentifier = message.contributedByCurrentUser ? WLMyMessageCellIdentifier : WLMessageCellIdentifier;
    WLMessageCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [cell setShowName:[self.chat.messagesWithName containsObject:message]];
    cell.entry = message;
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:@"date"]) {
        WLMessageDateView* view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLMessageDateView" forIndexPath:indexPath];
        view.message = [self.chat.entries tryObjectAtIndex:indexPath.item];
        return view;
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        WLLoadingView* loadingView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:WLLoadingViewIdentifier forIndexPath:indexPath];
        if (self.chat.wrap) {
            loadingView.error = NO;
            [self appendMessages:^{
            } failure:^(NSError *error) {
                [error show];
                loadingView.error = YES;
            }];
        }
        return loadingView;
    } else {
        WLTypingViewCell* typingView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLTypingViewCell" forIndexPath:indexPath];
        typingView.names = self.chat.typingNames;
        return typingView;
    }
}

- (CGFloat)heightOfMessageCell:(WLMessage *)message {
    BOOL containsName = [self.chat.messagesWithName containsObject:message];
    CGFloat commentHeight = WLCalculateHeightString(message.text, self.messageFont, WLMaxTextViewWidth);
    CGFloat topInset = (containsName ? WLMessageNameInset : WLMessageVerticalInset);
    CGFloat bottomInset = WLMessageNameInset;
    commentHeight = topInset + commentHeight + bottomInset;
    return MAX (containsName ? WLMessageWithNameMinimumCellHeight : WLMessageWithoutNameMinimumCellHeight, commentHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLMessage *message = [self.chat.entries tryObjectAtIndex:indexPath.item];
    return CGSizeMake(collectionView.width, [self heightOfMessageCell:message]);
}

- (CGSize)collectionView:(UICollectionView *)collectionView sizeForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:@"date"]) {
        WLMessage *message = [self.chat.entries tryObjectAtIndex:indexPath.item];
        return [self.chat.messagesWithDay containsObject:message] ? CGSizeMake(collectionView.width, WLMessageDayLabelHeight) : CGSizeZero;
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        if (self.chat.completed) return CGSizeZero;
        return CGSizeMake(collectionView.width, WLLoadingViewDefaultSize);
    } else {
        if (!self.chat.showTypingView) return CGSizeZero;
        return CGSizeMake(collectionView.width, MAX(WLTypingViewMinHeight, [self.chat.typingNames heightWithFont:[UIFont preferredFontWithName:WLFontOpenSansRegular preset:WLFontPresetSmall] width:WLMaxTextViewWidth]));
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView bottomInteritemSpacingForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLMessage *message = [self.chat.entries tryObjectAtIndex:indexPath.item];
    if ([self.chat.messagesWithDay containsObject:message]) {
        return 0;
    } else if ([self.chat.messagesWithName containsObject:message]) {
        return WLMessageGroupSpacing;
    } else {
        return 3;
    }
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    self.messageFont = [self.messageFont preferredFontWithPreset:WLFontPresetNormal];
    [self.collectionView reloadData];
}

@end
