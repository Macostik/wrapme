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
#import "WLChatCollectionViewLayout.h"
#import "WLUnreadMessagesView.h"

CGFloat WLMaxTextViewWidth;

@interface WLChatViewController () <UICollectionViewDataSource, UICollectionViewDelegate, WLComposeBarDelegate, UICollectionViewDelegateFlowLayout, WLKeyboardBroadcastReceiver, WLEntryNotifyReceiver, WLChatDelegate, WLChatCollectionViewLayoutDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@property (nonatomic, readonly) WLChatCollectionViewLayout* layout;

@property (weak, nonatomic) id operation;

@property (nonatomic) BOOL typing;

@property (strong, nonatomic) WLChat *chat;

@property (strong, nonatomic) UIFont* messageFont;

@property (weak, nonatomic) WLRefresher* refresher;

@property (nonatomic) BOOL animating;

@property (weak, nonatomic) WLMessage* newerVisibleMessage;

@end

@implementation WLChatViewController

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    self.collectionView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (WLCollectionViewFlowLayout *)layout {
	return (WLCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadChatAfterApplicationBecameActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)reloadChatAfterApplicationBecameActive {
    self.chat = [WLChat chatWithWrap:self.wrap];
    self.chat.delegate = self;
    [self reloadData];
    [self scrollToLastUnreadMessage];
}

- (void)viewDidLoad {
    
    [self.collectionView registerNib:[WLLoadingView nib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WLLoadingViewIdentifier];
    [self.collectionView registerNib:[WLTypingViewCell nib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"WLTypingViewCell"];
    [self.collectionView registerNib:[WLMessageDateView nib] forSupplementaryViewOfKind:@"date" withReuseIdentifier:@"WLMessageDateView"];
    [self.collectionView registerNib:[WLUnreadMessagesView nib] forSupplementaryViewOfKind:@"unreadMessagesView" withReuseIdentifier:@"WLUnreadMessagesView"];
    [self.layout registerItemFooterSupplementaryViewKind:@"date"];
    [self.layout registerItemFooterSupplementaryViewKind:@"unreadMessagesView"];
    
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
    [self scrollToLastUnreadMessage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.wrap.messages all:^(WLMessage *message) {
        [message markAsRead];
    }];
}

- (void)scrollToLastUnreadMessage {
    run_after(.05, ^{
        __weak __typeof(self)weakSelf = self;
        WLMessage *unreadMessage = [self.chat.unreadMessages lastObject];
        if (unreadMessage.valid) {
            NSIndexPath *indexPathForCell = [NSIndexPath indexPathForItem:[weakSelf.chat.entries indexOfObject:unreadMessage] inSection:0];
            if (indexPathForCell.item != NSNotFound) {
                [self.collectionView scrollToItemAtIndexPath:indexPathForCell atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
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
            [weakSelf.collectionView reloadData];
        });
    } else {
        if (failure) failure(nil);
    }
}

- (void)insertMessage:(WLMessage*)message {
    UIApplicationState applicationState = [UIApplication sharedApplication].applicationState;
    if (applicationState == UIApplicationStateBackground) {
        return;
    }
    BOOL applicationActive = applicationState == UIApplicationStateActive;
    __weak typeof(self)weakSelf = self;
    runUnaryQueuedOperation(@"wl_chat_insertion_queue", ^(WLOperation *operation) {
        if ([weakSelf.chat.entries containsObject:message]) {
            [operation finish];
            return;
        }

        UICollectionView *collectionView = weakSelf.collectionView;
        if (!weakSelf.animating && (collectionView.contentOffset.y > collectionView.minimumContentOffset.y || !applicationActive)) {
            CGFloat offset = collectionView.contentOffset.y;
            CGFloat contentHeight = collectionView.contentSize.height;
            [weakSelf.chat addEntry:message];
            [collectionView layoutIfNeeded];
            offset += collectionView.contentSize.height - contentHeight;
            [collectionView trySetContentOffset:CGPointMake(0, offset) animated:NO];
            [operation finish];
        } else {
            if (!collectionView.scrollable) {
                [weakSelf.chat addEntry:message];
                [operation finish];
                return;
            }
            [weakSelf performInsertAnimation:^(WLBlock completion) {
                [weakSelf.chat addEntry:message];
                [collectionView reloadData];
                [collectionView layoutIfNeeded];
                CGPoint minimumContentOffset = collectionView.minimumContentOffset;
                collectionView.contentOffset = CGPointMake(minimumContentOffset.x, minimumContentOffset.y + [weakSelf heightOfMessageCell:message]);
                [collectionView setMinimumContentOffsetAnimated:YES];
                run_after(0.5, ^{
                    completion();
                    [operation finish];
                });
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
    }
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier entryAdded:(WLMessage *)message {
    [message markAsRead];
    [self insertMessage:message];
}

- (void)notifier:(WLEntryNotifier *)notifier entryDeleted:(WLMessage *)message {
    [self.chat resetEntries:[self.wrap messages]];
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
        self.wrap.lastUnread = self.newerVisibleMessage.createdAt;
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

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        return 0;
    }
    return [self.chat.entries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLMessage* message = [self.chat.entries tryObjectAtIndex:indexPath.item];
    NSString *cellIdentifier = cellIdentifier = message.contributedByCurrentUser ? WLMyMessageCellIdentifier : WLMessageCellIdentifier;
    WLMessageCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [cell setShowName:[self.chat.messagesWithName containsObject:message]];
    cell.entry = message;
    cell.layer.geometryFlipped = YES;
    if (self.newerVisibleMessage == nil || [self.newerVisibleMessage.createdAt earlier:message.createdAt]) {
        self.newerVisibleMessage = message;
    }
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *supplementaryView = nil;
    if ([kind isEqualToString:@"date"]) {
        WLMessageDateView* view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLMessageDateView" forIndexPath:indexPath];
        view.message = [self.chat.entries tryObjectAtIndex:indexPath.item];
        supplementaryView = view;
    } else if ([kind isEqualToString:@"unreadMessagesView"]) {
        WLUnreadMessagesView *unreadMessagesView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLUnreadMessagesView" forIndexPath:indexPath];
        [unreadMessagesView setNumberOfUnreadMessages:[self.chat.unreadMessages count]];
        supplementaryView = unreadMessagesView;
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        WLLoadingView* loadingView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:WLLoadingViewIdentifier forIndexPath:indexPath];
        if (self.chat.wrap) {
            loadingView.error = NO;
            [self appendMessages:^{
            } failure:^(NSError *error) {
                [error showIgnoringNetworkError];
                loadingView.error = YES;
            }];
        }
        loadingView.layer.geometryFlipped = YES;
        supplementaryView = loadingView;
    } else {
        WLTypingViewCell* typingView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLTypingViewCell" forIndexPath:indexPath];
        typingView.names = self.chat.typingNames;
        supplementaryView = typingView;
    }
    supplementaryView.layer.geometryFlipped = YES;
    return supplementaryView;
}

- (CGFloat)heightOfMessageCell:(WLMessage *)message {
    BOOL containsName = [self.chat.messagesWithName containsObject:message];
    CGFloat commentHeight = [message.text heightWithFont:self.messageFont width:WLMaxTextViewWidth];
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
    } else if ([kind isEqualToString:@"unreadMessagesView"]) {
        WLMessage *message = [self.chat.entries tryObjectAtIndex:indexPath.item];
        return (message == [self.chat.unreadMessages lastObject]) ? CGSizeMake(collectionView.width, WLMessageDayLabelHeight) : CGSizeZero;
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        if (self.chat.completed) return CGSizeZero;
        if (self.chat.entries.nonempty) {
            return CGSizeMake(collectionView.width, WLLoadingViewDefaultSize);
        } else {
            return CGSizeMake(collectionView.width, collectionView.height - collectionView.verticalContentInsets);
        }
    } else {
        if (!self.chat.showTypingView) return CGSizeZero;
        return CGSizeMake(collectionView.width, MAX(WLTypingViewMinHeight, [self.chat.typingNames heightWithFont:[UIFont preferredFontWithName:WLFontOpenSansRegular preset:WLFontPresetSmaller] width:WLMaxTextViewWidth]));
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView bottomSpacingForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLMessage *message = [self.chat.entries tryObjectAtIndex:indexPath.item];
    if ([self.chat.messagesWithDay containsObject:message]) {
        return 0;
    } else if ([self.chat.messagesWithName containsObject:message]) {
        return [self.chat.unreadMessages lastObject] == message ? 0 : WLMessageGroupSpacing;
    } else {
        return [self.chat.unreadMessages lastObject] == message ? 0 : 3;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView topSpacingForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:@"unreadMessagesView"]) {
        return 12;
    }
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView bottomSpacingForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:@"unreadMessagesView"]) {
        return 12;
    }
    return 0;
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    self.messageFont = [self.messageFont preferredFontWithPreset:WLFontPresetNormal];
    [self.collectionView reloadData];
}

@end
