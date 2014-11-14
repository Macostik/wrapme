//
//  WLChatViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSDate+Additions.h"
#import "NSDate+Formatting.h"
#import "NSObject+NibAdditions.h"
#import "NSString+Additions.h"
#import "UIDevice+SystemVersion.h"
#import "UIFont+CustomFonts.h"
#import "UIScrollView+Additions.h"
#import "UIView+AnimationHelper.h"
#import "UIView+Shorthand.h"
#import "WLAPIManager.h"
#import "WLChat.h"
#import "WLChatViewController.h"
#import "WLCollectionViewFlowLayout.h"
#import "WLComposeBar.h"
#import "WLEntryNotifier.h"
#import "WLGroupedSet.h"
#import "WLInternetConnectionBroadcaster.h"
#import "WLKeyboard.h"
#import "WLLoadingView.h"
#import "WLMessageCell.h"
#import "WLMessageGroupCell.h"
#import "WLNotification.h"
#import "WLRefresher.h"
#import "WLSignificantTimeBroadcaster.h"
#import "WLSoundPlayer.h"
#import "WLTypingViewCell.h"
#import "WLUser.h"
#import "WLWrap.h"

static NSUInteger WLChatTypingSection = 0;
static NSUInteger WLChatMessagesSection = 1;
static NSUInteger WLChatLoadingSection = 2;

CGFloat WLMaxTextViewWidth;

@interface WLChatViewController () <UICollectionViewDataSource, UICollectionViewDelegate, WLComposeBarDelegate, UICollectionViewDelegateFlowLayout, WLKeyboardBroadcastReceiver, WLEntryNotifyReceiver, WLChatDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@property (nonatomic, readonly) WLCollectionViewFlowLayout* layout;

@property (weak, nonatomic) id operation;

@property (nonatomic) BOOL typing;

@property (strong, nonatomic) WLChat *chat;

@property (strong, nonatomic) UIFont* messageFont;

@property (weak, nonatomic) WLRefresher* refresher;

@property (nonatomic) BOOL animating;

@property (strong, nonatomic) NSIndexSet* supplementarySections;

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
	[super viewDidLoad];
    
    NSMutableIndexSet* supplementarySections = [NSMutableIndexSet indexSetWithIndex:WLChatTypingSection];
    [supplementarySections addIndex:WLChatLoadingSection];
    self.supplementarySections = [supplementarySections copy];
    
    UICollectionView *collectionView = self.collectionView;
    
    [self updateEdgeInsets:0];
    self.refresher = [WLRefresher refresher:collectionView target:self action:@selector(refreshMessages:) style:WLRefresherStyleOrange];
    
    collectionView.contentOffset = CGPointMake(0, -self.composeBar.height);
    
    collectionView.transform = CGAffineTransformMakeRotation(M_PI);
    
    self.messageFont = [UIFont lightFontOfSize:15];
    
    WLMaxTextViewWidth = [UIScreen mainScreen].bounds.size.width - 2*WLAvatarWidth;
    
	__weak typeof(self)weakSelf = self;
    [self.wrap fetchIfNeeded:^(id object) {
        weakSelf.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", WLString(weakSelf.wrap.name)];
    } failure:^(NSError *error) {
    }];
	
	self.composeBar.placeholder = @"Write your message ...";
    self.chat = [WLChat chatWithWrap:self.wrap];
    self.chat.delegate = self;

    if (self.wrap.messages.nonempty) {
        [self refreshMessages:^{
        } failure:^(NSError *error) {
            [error show];
        }];
    }
	
	self.backSwipeGestureEnabled = YES;
	
    [[WLMessage notifier] addReceiver:self];
    [[WLSignificantTimeBroadcaster broadcaster] addReceiver:self];
}

- (void)updateEdgeInsets:(CGFloat)keyboardHeight {
    UICollectionView *collectionView = self.collectionView;
    UIEdgeInsets insets = UIEdgeInsetsMake(self.composeBar.height + keyboardHeight, 0, 64, 0);
    collectionView.contentInset = insets;
    insets.right = collectionView.width - 6;
    collectionView.scrollIndicatorInsets = insets;
    [self.layout invalidate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
    [self.composeBar becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.wrap.messages all:^(WLMessage *message) {
        if(!NSNumberEqual(message.unread, @NO)) message.unread = @NO;
    }];
}

- (void)keyboardWillShow:(WLKeyboard *)keyboard {
    [super keyboardWillShow:keyboard];
    
    [UIView performWithoutAnimation:^{
        [self updateEdgeInsets:keyboard.height];
        [self.collectionView scrollToTopAnimated:self.viewAppeared];
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

- (void)performInsertAnimation:(void (^)(WLBlock completion))animation {
    if (!self.animating) {
        self.animating = YES;
        __weak typeof(self)weakSelf = self;
        [self.collectionView reloadData];
        [self.collectionView performBatchUpdates:nil completion:nil];
        animation(^{
            weakSelf.animating = NO;
            [weakSelf reloadData];
        });
    }
}

- (void)insertMessage:(WLMessage*)message {
    if ([self.chat.entries containsObject:message]) return;
    __weak typeof(self)weakSelf = self;
    [self performInsertAnimation:^(WLBlock completion) {
        [weakSelf.chat addEntry:message];
        [weakSelf.collectionView performBatchUpdates:^{
            [weakSelf.collectionView reloadSections:weakSelf.supplementarySections];
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[weakSelf.chat.entries indexOfObject:message] inSection:WLChatMessagesSection];
            [weakSelf.collectionView insertItemsAtIndexPaths:@[indexPath]];
        } completion:^(BOOL finished) {
            completion();
        }];
    }];
}

- (void)refreshMessages:(WLRefresher*)sender {
    [self refreshMessages:^{
        [sender setRefreshing:NO animated:YES];
    } failure:^(NSError *error) {
        [error show];
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

- (void)reloadData {
    if (!self.animating) {
        [self.collectionView reloadData];
        [self.layout invalidate];
    }
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier messageAdded:(WLMessage *)message {
    if (!NSNumberEqual(message.unread, @NO)) message.unread = @NO;
    [self insertMessage:message];
}

- (void)notifier:(WLEntryNotifier *)notifier messageDeleted:(WLMessage *)message {
    [self.chat resetEntries:[self.wrap messages]];
}

- (void)notifier:(WLEntryNotifier *)notifier messageUpdated:(WLMessage *)message {
    [self.chat addEntry:message];
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
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

#pragma mark - WLComposeBarDelegate

- (void)sendMessageWithText:(NSString*)text {
    __weak typeof(self)weakSelf = self;
    [self.wrap uploadMessage:text success:^(WLMessage *message) {
		[weakSelf.collectionView scrollToTopAnimated:YES];
        [message playSoundBySendEvent];
    } failure:^(NSError *error) {
		[error show];
        [weakSelf.composeBar performSelector:@selector(setText:) withObject:text afterDelay:0.0f];
    }];
    [weakSelf.collectionView scrollToTopAnimated:YES];
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
    [self updateEdgeInsets:[WLKeyboard keyboard].height];
    [self.collectionView scrollToTopAnimated:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([self.supplementarySections containsIndex:section]) {
        return 0;
    }
    return [self.chat.entries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLMessage* message = [self.chat.entries tryObjectAtIndex:indexPath.item];
    WLMessage* previousMessage = [self.chat.entries tryObjectAtIndex:indexPath.item + 1];
    BOOL isMyComment = [message.contributor isCurrentUser];
    NSString *cellIdentifier = cellIdentifier = isMyComment ? WLMyMessageCellIdentifier : WLMessageCellIdentifier;
    WLMessageCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.showAvatar = (previousMessage == nil || previousMessage.contributor != message.contributor);
    cell.showName = !isMyComment && cell.showAvatar;
    cell.showDay = previousMessage == nil || ![previousMessage.createdAt isSameDay:message.createdAt];
    cell.entry = message;
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        WLTypingViewCell* typingView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLTypingViewCell" forIndexPath:indexPath];
        typingView.names = self.chat.typingNames;
        return typingView;
    } else {
        WLLoadingView* loadingView = [WLLoadingView dequeueInCollectionView:collectionView indexPath:indexPath];
        if (self.chat.wrap) {
            loadingView.error = NO;
            [self appendMessages:^{
            } failure:^(NSError *error) {
                [error show];
                loadingView.error = YES;
            }];
        }
        return loadingView;
    }
}

- (CGFloat)heightOfMessageCell:(WLMessage *)message containsName:(BOOL)containsName {
	CGFloat commentHeight = [message.text heightWithFont:self.messageFont width:WLMaxTextViewWidth cachingKey:"messageCellHeight"];
    CGFloat topInset = (containsName ? WLMessageNameInset : WLMessageVerticalInset);
    CGFloat bottomInset = WLMessageVerticalInset;
    CGFloat bottomConstraint = WLMessageCellBottomConstraint;
    commentHeight = topInset + commentHeight + bottomInset + bottomConstraint;
    return MAX (WLMessageMinimumCellHeight, commentHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLMessage *message = [self.chat.entries tryObjectAtIndex:indexPath.item];
    WLMessage* previousMessage = [self.chat.entries tryObjectAtIndex:indexPath.item + 1];
    BOOL isMyComment = [message.contributor isCurrentUser];
    BOOL containsName = !isMyComment && (previousMessage == nil || previousMessage.contributor != message.contributor);
    return CGSizeMake(collectionView.width, [self heightOfMessageCell:message containsName:containsName]);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (section != WLChatLoadingSection || self.chat.completed) return CGSizeZero;
    return CGSizeMake(collectionView.width, WLLoadingViewDefaultSize);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (section != WLChatTypingSection || !self.chat.showTypingView) return CGSizeZero;
    return CGSizeMake(collectionView.width, MAX(WLTypingViewMinHeight, [self.chat.typingNames heightWithFont:[UIFont regularFontOfSize:14] width:WLMaxTextViewWidth cachingKey:"typingViewHeight"]));
}

@end
