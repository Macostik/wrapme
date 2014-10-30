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
#import "WLNotificationCenter.h"
#import "WLNotification.h"
#import "UIView+AnimationHelper.h"
#import "WLTypingView.h"
#import "WLChatGroupSet.h"
#import "UIDevice+SystemVersion.h"

CGFloat WLMaxTextViewWidth;

@interface WLChatViewController () <UICollectionViewDataSource, UICollectionViewDelegate, WLComposeBarDelegate, UICollectionViewDelegateFlowLayout, WLKeyboardBroadcastReceiver, WLEntryNotifyReceiver>

@property (assign, nonatomic) BOOL hasTypingUsers;

@property (nonatomic) BOOL shouldAppendMoreMessages;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@property (nonatomic, readonly) WLCollectionViewFlowLayout* layout;

@property (nonatomic) CGFloat keyboardHeight;

@property (weak, nonatomic) id operation;

@property (nonatomic) BOOL typing;

@property (strong, nonatomic) WLMessage *message;

@property (weak, nonatomic) IBOutlet WLTypingView *typingView;

@property (strong, nonatomic) WLChatGroupSet *chatGroup;

@end

@implementation WLChatViewController

- (WLCollectionViewFlowLayout *)layout {
	return (WLCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    __weak typeof(self)weakSelf = self;
    WLMaxTextViewWidth = [UIScreen mainScreen].bounds.size.width - WLAvatarWidth - WLPadding;
    self.shouldAppendMoreMessages = YES;
    
    self.chatGroup = [[WLChatGroupSet alloc] init];
	
	if (self.wrap.name.nonempty) {
		self.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", WLString(self.wrap.name)];
	} else {
		[self.wrap fetch:nil success:^(NSOrderedSet *candies) {
			weakSelf.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", WLString(weakSelf.wrap.name)];
		} failure:^(NSError *error) {
		}];
	}

	[WLRefresher refresher:self.collectionView target:self action:@selector(refreshMessages:) style:WLRefresherStyleOrange];
	self.collectionView.transform = CGAffineTransformMakeRotation(M_PI);
	self.composeBar.placeholder = @"Write your message ...";
	
	[self addMessages:self.wrap.messages pullDownToRefresh:NO];
    [self refreshMessages:nil];
	
	self.backSwipeGestureEnabled = YES;
	
    [[WLMessage notifier] addReceiver:self];
    [[WLSignificantTimeBroadcaster broadcaster] addReceiver:self];
    [[WLNotificationCenter defaultCenter] addReceiver:self];
    [[WLNotificationCenter defaultCenter] subscribeOnTypingChannel:self.wrap success:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.wrap.messages all:^(WLMessage *message) {
        if(!NSNumberEqual(message.unread, @NO)) message.unread = @NO;
    }];
    [self.composeBar becomeFirstResponder];
}

- (void)setShouldAppendMoreMessages:(BOOL)shouldAppendMoreMessages {
	_shouldAppendMoreMessages = shouldAppendMoreMessages;
	if (shouldAppendMoreMessages) {
		self.layout.loadingView = [WLLoadingView instance];
	} else {
		self.layout.loadingView = nil;
	}
}

- (void)setMessages:(NSOrderedSet*)messages {
    [self.chatGroup resetEntries:messages];
    [self.collectionView reloadData];
}

- (void)addMessages:(NSOrderedSet*)messages pullDownToRefresh:(BOOL)flag {
    [self.chatGroup addMessages:messages pullDownToRefresh:flag];
	[self.collectionView reloadData];
}

- (void)insertMessage:(WLMessage*)message {
    self.message = message;
    [self.chatGroup addMessage:message];
    [self.collectionView reloadData];
}

- (void)refreshMessages:(WLRefresher*)sender {
	__weak typeof(self)weakSelf = self;
    WLPaginatedSet* group = [self.chatGroup.entries firstObject];
    WLMessage* message = [group.entries firstObject];
    if (!message) {
        [self loadMessages:^{
            [sender setRefreshing:NO animated:YES];
        }];
        return;
    }
    [self.wrap messagesNewer:message.createdAt success:^(NSOrderedSet *messages) {
        if (!weakSelf.wrap.messages.nonempty) weakSelf.shouldAppendMoreMessages = NO;
        if (messages.nonempty) {
            [weakSelf addMessages:messages pullDownToRefresh:YES];
        }
        [sender setRefreshing:NO animated:YES];
    } failure:^(NSError *error) {
		[error showIgnoringNetworkError];
		[sender setRefreshing:NO animated:YES];
    }];
}

- (void)loadMessages:(WLBlock)completion {
    __weak typeof(self)weakSelf = self;
    [self.wrap messages:^(NSOrderedSet *messages) {
        if (!weakSelf.wrap.messages.nonempty) weakSelf.shouldAppendMoreMessages = NO;
		[weakSelf setMessages:messages];
        if (completion) {
            completion();
        }
    } failure:^(NSError *error) {
		[error showIgnoringNetworkError];
        if (completion) {
            completion();
        }
    }];
}

- (void)appendMessages {
	if (self.operation) return;
	__weak typeof(self)weakSelf = self;
    WLPaginatedSet* lastGroup = [self.chatGroup.entries lastObject];
    WLMessage* olderMessage = [lastGroup.entries lastObject];
    WLPaginatedSet* firstGroup = [self.chatGroup.entries firstObject];
    WLMessage* newerMessage = [firstGroup.entries firstObject];
	self.operation = [self.wrap messagesOlder:olderMessage.createdAt newer:newerMessage.createdAt success:^(NSOrderedSet *messages) {
		weakSelf.shouldAppendMoreMessages = messages.count >= WLPageSize;
        if (messages.nonempty) {
            [weakSelf addMessages:messages pullDownToRefresh:NO];
        }
	} failure:^(NSError *error) {
		weakSelf.shouldAppendMoreMessages = NO;
		[error showIgnoringNetworkError];
	}];
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier messageAdded:(WLMessage *)message {
    if (!NSNumberEqual(message.unread, @NO)) message.unread = @NO;
    [self insertMessage:message];
}

- (void)notifier:(WLEntryNotifier *)notifier messageDeleted:(WLMessage *)message {
    [self setMessages:[self.wrap messages]];
}

- (void)notifier:(WLEntryNotifier *)notifier messageUpdated:(WLMessage *)message {
    [self.chatGroup addMessage:message];
    [self.collectionView reloadData];
}

- (WLWrap *)notifierPreferredWrap:(WLEntryNotifier *)notifier {
    return self.wrap;
}

#pragma mark - WlSignificantTimeBroadcasterReceiver

- (void)broadcaster:(WLSignificantTimeBroadcaster *)broadcaster didChangeSignificantTime:(id)object {
    [self setMessages:[self.wrap messages]];
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
    self.typing = NO;
    [[WLNotificationCenter defaultCenter] unsubscribeFromTypingChannel];
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
}

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
    self.typing = !text.nonempty;
	[self sendMessageWithText:text];
}

- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar *)composeBar {
	return NO;
}

- (void)setTyping:(BOOL)typing {
    if (_typing != typing) {
        _typing = typing;
        if (typing) {
            [[WLNotificationCenter defaultCenter] beginTyping];
        } else {
            [[WLNotificationCenter defaultCenter] endTyping];
        }
    }
}

- (void)composeBarDidChangeText:(WLComposeBar*)composeBar {
    __weak __typeof(self)weakSelf = self;
    if ([[WLNotificationCenter defaultCenter] isSubscribedOnTypingChannel:self.wrap]) {
        weakSelf.typing = composeBar.text.nonempty;
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.chatGroup.entries count] + NSINTEGER_DEFINED;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (!section ) {
        return self.hasTypingUsers;
    }
    WLPaginatedSet *group = [self.chatGroup.entries tryObjectAtIndex:section - 1];
    return [group.entries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLMessageCell* cell = [self prepareCellForIndexPath:indexPath];
    [self handlePaginationWithIndexPath:indexPath];

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.section ) {
        WLMessageGroupCell* groupCell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"WLMessageGroupCell" forIndexPath:indexPath];
        groupCell.dateLabel.text = [[NSDate date] string];
        return groupCell;
    }
	WLMessageGroupCell* groupCell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"WLMessageGroupCell" forIndexPath:indexPath];
        WLPaginatedSet *group = [self.chatGroup.entries tryObjectAtIndex:indexPath.section - 1];
        groupCell.group = group;
	
	return groupCell;
}

- (CGFloat)heightOfMessageCell:(WLMessage *)message equalLastMessage:(WLMessage *)lastmessage {
	CGFloat commentHeight  = ceilf([message.text boundingRectWithSize:CGSizeMake(WLMaxTextViewWidth, CGFLOAT_MAX)
																	 options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont lightFontOfSize:15]} context:nil].size.height);
    if (![message isEqualToEntry:lastmessage]) {
        return  commentHeight + WLMessageAuthorLabelHeight/2;
    }
    commentHeight += 2*WLMessageAuthorLabelHeight;
    commentHeight += [message.contributor isCurrentUser] ? .0f : WLNameLabelHeight;
	return MAX(WLMessageMinimumCellHeight, commentHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.section ) {
        return CGSizeMake(collectionView.width, 66);
    }

    WLPaginatedSet *group = [self.chatGroup.entries tryObjectAtIndex:indexPath.section - 1];
    WLMessage *message = [group.entries tryObjectAtIndex:indexPath.row];
    WLMessage *lastMessage = group.entries.lastObject;

    return CGSizeMake(collectionView.width, [self heightOfMessageCell:message equalLastMessage:lastMessage]);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (!section) {
        return CGSizeZero;
    }
    WLPaginatedSet *group = [self.chatGroup.entries tryObjectAtIndex:section - 1];
    if (group == self.chatGroup.entries.lastObject) {
         return CGSizeMake(collectionView.width, 32);
    }
    WLPaginatedSet *nextGroup = [self.chatGroup.entries tryObjectAtIndex:section];
        if (![[group date] isSameDay:[nextGroup date]]) {
            return CGSizeMake(collectionView.width, 32);
        }
    
    return CGSizeZero;
}

- (void)handlePaginationWithIndexPath:(NSIndexPath*)indexPath {
	if (!self.shouldAppendMoreMessages) {
		return;
	}
    NSUInteger numberOfSections = [self.collectionView numberOfSections];
    NSUInteger numberOfItems = [self.collectionView numberOfItemsInSection:indexPath.section];
	if (indexPath.section == numberOfSections - 1 && indexPath.item == numberOfItems - 1) {
		[self appendMessages];
	}
}

#pragma mark - WLNotificationReceiver

- (void)broadcaster:(WLNotificationCenter *)broadcaster didBeginTyping:(WLUser *)user {
    [self.typingView addUser:user];
    [self showTypingView:YES];
}

- (void)broadcaster:(WLNotificationCenter *)broadcaster didEndTyping:(WLUser *)user {
    [self.typingView removeUser:user];
    if (![self.typingView hasUsers]) {
        [self showTypingView:NO];
    }
}

- (WLMessageCell *)prepareCellForIndexPath:(NSIndexPath *)indexPath {
    WLMessageCell* cell = nil;
    NSString* cellIdentifier = nil;
    if (!indexPath.section) {
        cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"WLEmptyCell" forIndexPath:indexPath];
    } else {
        WLPaginatedSet *group = [self.chatGroup.entries tryObjectAtIndex:indexPath.section - 1];
        WLMessage* message = [group.entries objectAtIndex:indexPath.row];
        
        WLMessage *lastMessage = group.entries.lastObject;
        BOOL isMyComment = [message.contributor isCurrentUser];
        
        if ([message isEqualToEntry:lastMessage]) {
            cellIdentifier = isMyComment ? @"WLMyMessageCell" : @"WLMessageCell";
        } else {
            cellIdentifier =  isMyComment ? @"WLMyBubbleMessageCell" :
            @"WLBubbleMessageCell";
        }
        
        cell =  [self.collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.item = message;
        
        if ([message isEqualToEntry:self.message]) {
            [self slowUpAnimationCell:cell];
        }
    }
    
    return cell;
}

- (void)slowUpAnimationCell:(WLMessageCell*)cell {
    __weak __typeof(self)weakSelf = self;
    CGAffineTransform transform = cell.transform;
    CGAffineTransform transformRotate = self.collectionView.transform;
    CGFloat startPoint =  SystemVersionGreaterThanOrEqualTo8() ? self.view.height : -self.view.height;;
    CGAffineTransform transformTranslation = CGAffineTransformMakeTranslation(0, startPoint);
    cell.transform =  CGAffineTransformConcat(transformRotate, transformTranslation);
    [UIView animateWithDuration:1.0 delay:0.0f options:UIViewAnimationOptionCurveLinear  animations:^{
            cell.transform = transform;
    } completion:^(BOOL finished) {
        weakSelf.message = nil;
    }];
}

- (void)showTypingView:(BOOL)flag {
    __weak __typeof(self)weakSelf = self;
    self.hasTypingUsers = flag;
    [self.collectionView reloadData];
    [UIView animateWithDuration:.5 delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        weakSelf.typingView.transform =  flag ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0, weakSelf.collectionView.height);
    } completion:NULL];
}

@end
