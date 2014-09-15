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
#import "WLKeyboardBroadcaster.h"
#import "NSDate+Additions.h"
#import "NSString+Additions.h"
#import "WLBlocks.h"
#import "WLWrapBroadcaster.h"
#import "WLGroupedSet.h"
#import "WLSignificantTimeBroadcaster.h"
#import "WLNotificationCenter.h"
#import "WLNotification.h"

@interface WLChatViewController () <UICollectionViewDataSource, UICollectionViewDelegate, WLComposeBarDelegate, UICollectionViewDelegateFlowLayout, WLKeyboardBroadcastReceiver, WLWrapBroadcastReceiver>

@property (nonatomic, strong) WLGroupedSet* groups;

@property (strong, nonatomic) NSMutableOrderedSet *groupTyping;

@property (nonatomic) BOOL shouldAppendMoreMessages;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@property (weak, nonatomic) IBOutlet UILabel *indicator;

@property (nonatomic, readonly) WLCollectionViewFlowLayout* layout;

@property (nonatomic) CGFloat keyboardHeight;

@property (weak, nonatomic) id operation;

@property (nonatomic) BOOL typing;

@end

@implementation WLChatViewController

- (WLCollectionViewFlowLayout *)layout {
	return (WLCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.groups = [[WLGroupedSet alloc] init];
	
	if (self.wrap.name.nonempty) {
		self.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", WLString(self.wrap.name)];
	} else {
		__weak typeof(self)weakSelf = self;
		[self.wrap fetch:nil success:^(NSOrderedSet *candies) {
			weakSelf.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", WLString(weakSelf.wrap.name)];
		} failure:^(NSError *error) {
		}];
	}
	__weak typeof(self)weakSelf = self;
	[WLRefresher refresher:self.collectionView target:self action:@selector(refreshMessages:) style:WLRefresherStyleOrange];
	self.collectionView.transform = CGAffineTransformMakeRotation(M_PI);
	self.composeBar.placeholder = @"Write your message ...";
	
	[weakSelf setMessages:self.wrap.messages];
    [weakSelf refreshMessages:nil];
	
	self.backSwipeGestureEnabled = YES;
    self.indicator.cornerRadius = self.indicator.width/2;
	
	[[WLKeyboardBroadcaster broadcaster] addReceiver:self];
    [[WLWrapBroadcaster broadcaster] addReceiver:self];
    [[WLSignificantTimeBroadcaster broadcaster] addReceiver:self];
    [[WLNotificationCenter defaultCenter] addReceiver:self];
    if ([[WLAPIManager instance].environment.name isEqualToString:WLAPIEnvironmentProduction]) {
        [self.indicator removeFromSuperview];
        [[WLNotificationCenter defaultCenter] subscribeOnTypingChannel:self.wrap success:nil];
    } else {
        [[WLNotificationCenter defaultCenter] subscribeOnTypingChannel:self.wrap success:^ {
            weakSelf.indicator.backgroundColor = [UIColor greenColor];
        }];
    }
    self.groupTyping = [NSMutableOrderedSet orderedSet];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.shouldShowKeyboard) {
		[self.composeBar becomeFirstResponder];
	}
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
    [self.groups resetEntries:messages];
    [self.groups sort];
    [self.collectionView reloadData];
}

- (void)addMessages:(NSOrderedSet*)messages {
    [self.groups addEntries:messages];
    [self.groups sort];
	[self.collectionView reloadData];
}

- (void)insertMessage:(WLMessage*)message {
	[self.groups addEntry:message];
    [self.groups sort];
    [self.collectionView reloadData];
}

- (void)refreshMessages:(WLRefresher*)sender {
	__weak typeof(self)weakSelf = self;
    WLGroup* group = [self.groups.entries firstObject];
    WLMessage* message = [group.entries firstObject];
    if (!message) {
        [self loadMessages:^{
            [sender setRefreshing:NO animated:YES];
        }];
        return;
    }
    self.operation = [self.wrap messagesNewer:message.createdAt success:^(NSOrderedSet *messages) {
        weakSelf.shouldAppendMoreMessages = messages.count >= WLPageSize;
        if (messages.nonempty) {
            [weakSelf addMessages:messages];
        }
        [sender setRefreshing:NO animated:YES];
    } failure:^(NSError *error) {
		[error showIgnoringNetworkError];
		[sender setRefreshing:NO animated:YES];
    }];
}

- (void)loadMessages:(WLBlock)completion {
    __weak typeof(self)weakSelf = self;
    self.operation = [self.wrap messages:^(NSOrderedSet *messages) {
        weakSelf.shouldAppendMoreMessages = messages.count >= WLPageSize;
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
    WLGroup* group = [self.groups.entries lastObject];
    WLMessage* olderMessage = [group.entries lastObject];
    WLGroup* group1 = [self.groups.entries firstObject];
    WLMessage* newerMessage = [group1.entries firstObject];
	self.operation = [self.wrap messagesOlder:olderMessage.createdAt newer:newerMessage.createdAt success:^(NSOrderedSet *messages) {
		weakSelf.shouldAppendMoreMessages = messages.count >= WLPageSize;
        if (messages.nonempty) {
            [weakSelf addMessages:messages];
        }
	} failure:^(NSError *error) {
		weakSelf.shouldAppendMoreMessages = NO;
		[error showIgnoringNetworkError];
	}];
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster messageCreated:(WLMessage *)message {
    if (!NSNumberEqual(message.unread, @NO)) message.unread = @NO;
    [self insertMessage:message];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster messageRemoved:(WLMessage *)message {
    [self setMessages:[self.wrap messages]];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster messageChanged:(WLMessage *)message {
    for (WLGroup* group in self.groups.entries) {
        if ([group.entries containsObject:message] && ![group.date isSameDay:message.createdAt]) {
            [group.entries removeObject:message];
            if (![group.entries count]) {
                [self.groups.entries removeObject:group];
                break;
            }
        }
    }
    [self.groups addEntry:message];
    [self.groups sort];
    [self.collectionView reloadData];
}

- (WLWrap *)broadcasterPreferedWrap:(WLWrapBroadcaster *)broadcaster {
    return self.wrap;
}

#pragma mark - WLKeyboardBroadcastReceiver

- (void)broadcasterWillHideKeyboard:(WLKeyboardBroadcaster *)broadcaster {
	self.keyboardHeight = 0;
	self.collectionView.height = self.view.height - self.topView.height - self.composeBar.height;
	self.composeBar.y = CGRectGetMaxY(self.collectionView.frame);
	[self.collectionView reloadData];
}

- (void)broadcaster:(WLKeyboardBroadcaster *)broadcaster willShowKeyboardWithHeight:(NSNumber *)keyboardHeight {
	self.keyboardHeight = [keyboardHeight floatValue];
	self.collectionView.height = self.view.height - self.topView.height - self.composeBar.height - self.keyboardHeight;
	self.composeBar.y = CGRectGetMaxY(self.collectionView.frame);
	[self.collectionView reloadData];
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
        [weakSelf insertMessage:message];
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

- (void)composeBarHeightDidChanged:(WLComposeBar *)composeBar {
	[self changeDimentionsWithComposeBar:composeBar];
}

- (void)changeDimentionsWithComposeBar:(WLComposeBar *)composeBar {
	self.composeBar.height = composeBar.height;
	self.collectionView.height = self.view.height - self.topView.height - self.composeBar.height - self.keyboardHeight;
	self.composeBar.y = self.collectionView.height + self.topView.height;
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
    return [self.groups.entries count] + NSINTEGER_DEFINED;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (!section ) {
        return [self.groupTyping count];
    }
   
    WLGroup* group = [self.groups.entries tryObjectAtIndex:section - 1];
    return [group.entries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
   WLMessageCell* cell = nil;
    if (!indexPath.section) {
        WLUser *typingUser = [self.groupTyping objectAtIndex:indexPath.row];
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WLMessageCell" forIndexPath:indexPath];
        cell.item = typingUser;
    } else {
        WLGroup* group = [self.groups.entries tryObjectAtIndex:indexPath.section - 1];
        WLMessage* message = [group.entries objectAtIndex:indexPath.item];
        if (!NSNumberEqual(message.unread, @NO)) message.unread = @NO;
        BOOL isMyComment = [message.contributor isCurrentUser];
        NSString* cellIdentifier = isMyComment ? @"WLMyMessageCell" : @"WLMessageCell";
        cell =  [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.item = message;
    }
	
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
	groupCell.group = [self.groups.entries tryObjectAtIndex:indexPath.section - 1];
	return groupCell;
}

- (CGFloat)heightOfMessageCell:(WLMessage *)message {
	CGFloat commentHeight  = ceilf([message.text boundingRectWithSize:CGSizeMake(250, CGFLOAT_MAX)
																	 options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont lightFontOfSize:15]} context:nil].size.height);
	commentHeight += 2*WLMessageAuthorLabelHeight;
	return MAX(WLMessageMinimumCellHeight, commentHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.section ) {
        return CGSizeMake(collectionView.width, 66);
    }
	WLGroup* group = [self.groups.entries tryObjectAtIndex:indexPath.section - 1];
	WLMessage* message = [group.entries tryObjectAtIndex:indexPath.row];
	return CGSizeMake(collectionView.frame.size.width, [self heightOfMessageCell:message]);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (!section && [[[self.groups.entries firstObject] date] isToday]) {
        return CGSizeZero;
    }
	return CGSizeMake(collectionView.frame.size.width, 32);
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
    if(user) {
        [self.groupTyping insertObject:user atIndex:0];
        [self.collectionView reloadData];
    }
}

- (void)broadcaster:(WLNotificationCenter *)broadcaster didEndTyping:(WLUser *)user {
    if ([self.groupTyping containsObject:user]) {
        [self.groupTyping removeObject:user];
        [self.collectionView reloadData];
    }
}

@end
