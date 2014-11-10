//
//  WLChatViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLChatViewController.h"
#import "WLWrap.h"
#import "WLAPIManager.h"
#import "WLRefresher.h"
#import "WLMessageCell.h"
#import "WLUser.h"
#import "UIFont+CustomFonts.h"
#import "WLComposeBar.h"
#import "UIView+Shorthand.h"
#import "WLLoadingView.h"
#import "WLMessageGroupCell.h"
#import "NSDate+Formatting.h"
#import "NSObject+NibAdditions.h"
#import "WLCollectionViewFlowLayout.h"
#import "UIScrollView+Additions.h"
#import "WLKeyboard.h"
#import "NSDate+Additions.h"
#import "NSString+Additions.h"
#import "WLEntryNotifier.h"
#import "WLGroupedSet.h"
#import "WLSignificantTimeBroadcaster.h"
#import "WLInternetConnectionBroadcaster.h"
#import "WLNotification.h"
#import "UIView+AnimationHelper.h"
#import "WLTypingViewCell.h"
#import "WLChat.h"
#import "UIDevice+SystemVersion.h"

CGFloat WLMaxTextViewWidth;

@interface WLChatViewController () <UICollectionViewDataSource, UICollectionViewDelegate, WLComposeBarDelegate, UICollectionViewDelegateFlowLayout, WLKeyboardBroadcastReceiver, WLEntryNotifyReceiver, WLChatDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@property (nonatomic, readonly) WLCollectionViewFlowLayout* layout;

@property (weak, nonatomic) id operation;

@property (nonatomic) BOOL typing;

@property (strong, nonatomic) NSMutableSet* animatingMessages;

@property (strong, nonatomic) WLChat *chat;

@property (strong, nonatomic) UIFont* messageFont;

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
    
    UICollectionView *collectionView = self.collectionView;
    [collectionView registerNib:[WLLoadingView nib]
          forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                 withReuseIdentifier:@"WLLoadingView"];
    
	[super viewDidLoad];
    
    [self updateEdgeInsets:0];
    [WLRefresher refresher:collectionView target:self action:@selector(refreshMessages:) style:WLRefresherStyleOrange];
    [self updateEdgeInsets:216];
    
    collectionView.contentOffset = CGPointMake(0, -self.composeBar.height);
    
    collectionView.transform = CGAffineTransformMakeRotation(M_PI);
    
    self.messageFont = [UIFont lightFontOfSize:15];
    
    WLMaxTextViewWidth = [UIScreen mainScreen].bounds.size.width - 2*WLAvatarWidth - WLPadding;
    
    self.animatingMessages = [NSMutableSet set];
    
	__weak typeof(self)weakSelf = self;
    [self.wrap fetchIfNeeded:^(id object) {
        weakSelf.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", WLString(weakSelf.wrap.name)];
    } failure:^(NSError *error) {
    }];
	
	self.composeBar.placeholder = @"Write your message ...";
    self.chat = [[WLChat alloc] init];
    self.chat.delegate = self;
    self.chat.wrap = self.wrap;
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
    [self.layout invalidateLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    [self updateEdgeInsets:keyboard.height];
    [self.collectionView scrollToTopAnimated:self.viewAppeared];
}

- (void)keyboardWillHide:(WLKeyboard *)keyboard {
    [super keyboardWillHide:keyboard];
    [self updateEdgeInsets:0];
}

- (void)insertMessage:(WLMessage*)message {
    [self.animatingMessages addObject:message];
    [self.chat addMessage:message];
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
    WLPaginatedSet* group = [self.chat.entries firstObject];
    WLMessage* message = [group.entries firstObject];
    if (!message) {
        [self loadMessages:success failure:failure];
        return;
    }
    [self.wrap messagesNewer:message.createdAt success:^(NSOrderedSet *messages) {
        if (!weakSelf.wrap.messages.nonempty) weakSelf.chat.completed = YES;
        [weakSelf.chat addMessages:messages isNewer:YES];
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
    WLPaginatedSet* lastGroup = [self.chat.entries lastObject];
    WLMessage* olderMessage = [lastGroup.entries lastObject];
    WLPaginatedSet* firstGroup = [self.chat.entries firstObject];
    WLMessage* newerMessage = [firstGroup.entries firstObject];
    if (!olderMessage) {
        [self loadMessages:success failure:failure];
        return;
    }
	self.operation = [self.wrap messagesOlder:olderMessage.createdAt newer:newerMessage.createdAt success:^(NSOrderedSet *messages) {
		weakSelf.chat.completed = messages.count < WLPageSize;
        [weakSelf.chat addMessages:messages isNewer:NO];
        if (success) success();
	} failure:failure];
}

#pragma mark - WLChatDelegate

- (void)paginatedSetChanged:(WLPaginatedSet *)group {
    [self.collectionView reloadData];
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier messageAdded:(WLMessage *)message {
    if (!NSNumberEqual(message.unread, @NO)) message.unread = @NO;
    for (WLPaginatedSet* group in self.chat.entries) {
        if ([group.entries containsObject:message]) {
            return;
        }
    }
    [self insertMessage:message];
}

- (void)notifier:(WLEntryNotifier *)notifier messageDeleted:(WLMessage *)message {
    [self.chat resetEntries:[self.wrap messages]];
}

- (void)notifier:(WLEntryNotifier *)notifier messageUpdated:(WLMessage *)message {
    [self.chat addMessage:message];
    [self.collectionView reloadData];
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
    return [self.chat.entries count] + 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (!section ) {
        return self.chat.showTypingView;
    }
    WLPaginatedSet *group = [self.chat.entries tryObjectAtIndex:section - 1];
    if (group) {
        return [group.entries count];
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLMessageCell* cell = nil;
    NSString* cellIdentifier = nil;
    if (!indexPath.section) {
        WLTypingViewCell* typingView = [collectionView dequeueReusableCellWithReuseIdentifier:@"WLTypingView" forIndexPath:indexPath];
        typingView.names = self.chat.typingNames;
        cell = (id)typingView;
    } else {
        WLPaginatedSet *group = [self.chat.entries tryObjectAtIndex:indexPath.section - 1];
        WLMessage* message = [group.entries tryObjectAtIndex:indexPath.row];
        
        WLMessage *lastMessage = group.entries.lastObject;
        BOOL isMyComment = [message.contributor isCurrentUser];
        
        if ([message isEqualToEntry:lastMessage]) {
            cellIdentifier = isMyComment ? @"WLMyMessageCell" : @"WLMessageCell";
        } else {
            cellIdentifier =  isMyComment ? @"WLMyBubbleMessageCell" :
            @"WLBubbleMessageCell";
        }
        
        cell =  [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.entry = message;
        
        if ([self.animatingMessages containsObject:message]) {
            [self slowUpAnimationCell:cell message:message];
        }
    }
    return cell;
}

- (void)slowUpAnimationCell:(WLMessageCell*)cell message:(WLMessage*)message {
    __weak __typeof(self)weakSelf = self;
    CGAffineTransform transform = cell.transform;
    CGFloat startPoint = (SystemVersionGreaterThanOrEqualTo8() ? -1 : 1) * (cell.y + cell.height);
    cell.transform = CGAffineTransformTranslate(self.collectionView.transform, 0, 2*startPoint);
    [UIView animateWithDuration:0.7 delay:0.3 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        cell.transform = transform;
    } completion:^(BOOL finished) {
        [weakSelf.animatingMessages removeObject:message];
    }];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    WLPaginatedSet *group = [self.chat.entries tryObjectAtIndex:indexPath.section - 1];
    if (group) {
        WLMessageGroupCell* groupCell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLMessageGroupCell" forIndexPath:indexPath];
        groupCell.group = group;
        return groupCell;
    }
    WLLoadingView* loadingView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLLoadingView" forIndexPath:indexPath];
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

- (CGFloat)heightOfMessageCell:(WLMessage *)message equalLastMessage:(WLMessage *)lastmessage {
	CGFloat commentHeight = [message.text heightWithFont:self.messageFont width:WLMaxTextViewWidth cachingKey:"messageCellHeight"];
    if (![message isEqualToEntry:lastmessage]) {
        return  commentHeight + WLMessageAuthorLabelHeight/2;
    }
    commentHeight += 2*WLMessageAuthorLabelHeight;
    commentHeight += [message.contributor isCurrentUser] ? .0f : WLNameLabelHeight;
	return MAX (WLMessageMinimumCellHeight, commentHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.section ) {
        return CGSizeMake(collectionView.width, MAX(WLTypingViewMinHeight, [self.chat.typingNames heightWithFont:[UIFont regularFontOfSize:14] width:WLMaxTextViewWidth cachingKey:"typingViewHeight"]));
    }

    WLPaginatedSet *group = [self.chat.entries tryObjectAtIndex:indexPath.section - 1];
    WLMessage *message = [group.entries tryObjectAtIndex:indexPath.item];
    WLMessage *lastMessage = group.entries.lastObject;
    return CGSizeMake(collectionView.width, [self heightOfMessageCell:message equalLastMessage:lastMessage]);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (!section) {
        return CGSizeZero;
    }
    WLPaginatedSet *group = [self.chat.entries tryObjectAtIndex:section - 1];
    if (group) {
        if (group == self.chat.entries.lastObject) {
            return CGSizeMake(collectionView.width, 32);
        }
        WLPaginatedSet *nextGroup = [self.chat.entries tryObjectAtIndex:section];
        if (![[group date] isSameDay:[nextGroup date]]) {
            return CGSizeMake(collectionView.width, 32);
        }
        return CGSizeZero;
    }
    
    if (self.chat.completed) return CGSizeZero;
    return CGSizeMake(collectionView.width, 66);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeZero;
}

@end
