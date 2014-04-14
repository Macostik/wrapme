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
#import "WLCandy.h"
#import "WLUser.h"
#import "UIFont+CustomFonts.h"
#import "WLComposeBar.h"
#import "UIView+Shorthand.h"
#import "WLLoadingView.h"
#import "WLWrapDate.h"
#import "WLMessageGroupCell.h"
#import "NSDate+Formatting.h"
#import "NSObject+NibAdditions.h"

@interface WLChatViewController () <UICollectionViewDataSource, UICollectionViewDelegate, WLComposeBarDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSMutableArray* dates;

@property (nonatomic, weak) WLRefresher* refresher;

@property (nonatomic) BOOL shouldAppendMoreMessages;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@end

@implementation WLChatViewController
{
	BOOL loading;
	NSInteger messagesCount;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", self.wrap.name];
	
	__weak typeof(self)weakSelf = self;
	self.refresher = [WLRefresher refresherWithScrollView:self.collectionView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf refreshMessages];
	}];
	self.refresher.colorScheme = WLRefresherColorSchemeOrange;
	self.collectionView.transform = CGAffineTransformMakeRotation(M_PI);
	
	self.shouldAppendMoreMessages = YES;
	[self refreshMessages];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.shouldShowKeyboard) {
		[self.composeBar becomeFirstResponder];
	}
}

- (void)setShouldAppendMoreMessages:(BOOL)shouldAppendMoreMessages {
	_shouldAppendMoreMessages = shouldAppendMoreMessages;
}

- (NSMutableArray *)dates {
	if (!_dates) {
		_dates = [NSMutableArray array];
	}
	return _dates;
}

- (void)setMessages:(NSArray*)messages {
	messagesCount = 0;
	[self.dates removeAllObjects];
	[self addMessages:messages];
}

- (void)addMessages:(NSArray*)messages {
	messagesCount += [messages count];
		NSMutableArray* _messages = [NSMutableArray arrayWithArray:messages];
	
	while ([_messages count] > 0) {
		WLCandy* candy = [_messages firstObject];
		NSArray* dayMessages = [WLEntry entriesForDate:candy.updatedAt inArray:_messages];
		[self addMessages:dayMessages date:candy.updatedAt];
		[_messages removeObjectsInArray:dayMessages];
	}
	
	[self reloadCollectionView];
}

- (void)addMessages:(NSArray*)messages date:(NSDate*)date {
	WLWrapDate* dateObject = [self dateObjectWithDate:date];
	NSMutableArray* candies = [NSMutableArray arrayWithArray:dateObject.candies];
	[candies addObjectsFromArray:messages];
	dateObject.candies = [candies copy];
}

- (void)insertMessage:(WLCandy*)message {
	WLWrapDate* dateObject = [self dateObjectWithDate:message.updatedAt];
	NSMutableArray* candies = [NSMutableArray arrayWithArray:dateObject.candies];
	[candies insertObject:message atIndex:0];
	dateObject.candies = [candies copy];
}

- (WLWrapDate*)dateObjectWithDate:(NSDate*)date {
	for (WLWrapDate* dateObject in self.dates) {
		if ([dateObject.updatedAt isSameDay:date]) {
			return dateObject;
		}
	}
	WLWrapDate* dateObject = [[WLWrapDate alloc] init];
	dateObject.updatedAt = date;
	[self.dates addObject:dateObject];
	return dateObject;
}

- (void)refreshMessages {
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] chatMessages:self.wrap page:1 success:^(id object) {
		weakSelf.shouldAppendMoreMessages = [object count] == WLAPIChatPageSize;
		[weakSelf setMessages:object];
		[weakSelf.refresher endRefreshing];
	} failure:^(NSError *error) {
		[error show];
		[weakSelf.refresher endRefreshing];
	}];
}

- (void)appendMessages {
	if (loading) {
		return;
	}
	loading = YES;
	__weak typeof(self)weakSelf = self;
	NSUInteger page = floorf(messagesCount / WLAPIChatPageSize) + 1;
	[[WLAPIManager instance] chatMessages:self.wrap page:page success:^(id object) {
		weakSelf.shouldAppendMoreMessages = [object count] == WLAPIChatPageSize;
		[weakSelf addMessages:object];
		loading = NO;
	} failure:^(NSError *error) {
		[error show];
		loading = NO;
	}];
}

- (void)reloadCollectionView {
	[self.collectionView reloadData];
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - WLComposeBarDelegate

- (void)sendMessageWithText:(NSString*)text {
	if (text.length == 0) {
		return;
	}
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] addCandy:[WLCandy chatMessageWithText:text]
							   toWrap:self.wrap
							  success:^(id object) {
		[weakSelf insertMessage:object];
		[weakSelf.wrap broadcastChange];
		[weakSelf reloadCollectionView];
		[weakSelf.collectionView setContentOffset:CGPointZero animated:YES];
	} failure:^(NSError *error) {
		[error show];
	}];
}

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[self sendMessageWithText:text];
}

- (void)composeBarDidReturn:(WLComposeBar *)composeBar {
	[composeBar resignFirstResponder];
}

- (void)composeBarDidBeginEditing:(WLComposeBar *)composeBar {
	self.collectionView.height = self.view.height - self.topView.height - self.composeBar.height - 216;
	self.composeBar.y = CGRectGetMaxY(self.collectionView.frame);
	[self reloadCollectionView];
}

- (void)composeBarDidEndEditing:(WLComposeBar *)composeBar {
	self.collectionView.height = self.view.height - self.topView.height - self.composeBar.height;
	self.composeBar.y = CGRectGetMaxY(self.collectionView.frame);
	[self reloadCollectionView];
}

- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar *)composeBar {
	return NO;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return [self.dates count] + 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	if (section < [self.dates count]) {
		WLWrapDate* date = [self.dates objectAtIndex:section];
		return [date.candies count];
	} else {
		return self.shouldAppendMoreMessages;
	}
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section < [self.dates count]) {
		WLWrapDate* date = [self.dates objectAtIndex:indexPath.section];
		WLCandy* message = [date.candies objectAtIndex:indexPath.row];
		BOOL isMyComment = [message.contributor isCurrentUser];
		NSString* cellIdentifier = isMyComment ? @"WLMyMessageCell" : @"WLMessageCell";
		WLMessageCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
		cell.item = message;
		[self handlePaginationWithIndexPath:indexPath];
		return cell;
	} else {
		return [collectionView dequeueReusableCellWithReuseIdentifier:@"WLMessageLoadingView" forIndexPath:indexPath];
	}
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
		return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLMessageSpacingView" forIndexPath:indexPath];
	}
	
	WLMessageGroupCell* groupCell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"WLMessageGroupCell" forIndexPath:indexPath];
	groupCell.date = [self.dates objectAtIndex:indexPath.section];
	return groupCell;
}

- (CGFloat)heightOfMessageCell:(WLCandy *)comment {
	CGFloat commentHeight  = ceilf([comment.chatMessage boundingRectWithSize:CGSizeMake(260, CGFLOAT_MAX)
																	 options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont lightMicroFont]} context:nil].size.height);
	commentHeight = [comment.contributor isCurrentUser] ? commentHeight  : (commentHeight + 20);
	return MAX(44, commentHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section < [self.dates count]) {
		WLWrapDate* date = [self.dates objectAtIndex:indexPath.section];
		WLCandy* comment = [date.candies objectAtIndex:indexPath.row];
		return CGSizeMake(collectionView.frame.size.width, MAX(44, [self heightOfMessageCell:comment]));
	} else {
		if ([self.dates count] == 0) {
			return collectionView.frame.size;
		} else {
			return CGSizeMake(collectionView.frame.size.width, 66);
		}
	}
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
	if (section == 0 && section < [self.dates count]) {
		CGFloat contentHeight = 0;
		for (WLWrapDate * date in self.dates) {
			contentHeight += 32;
			for (WLCandy* comment in date.candies) {
				contentHeight += [self heightOfMessageCell:comment];
				if (contentHeight > collectionView.height) {
					return CGSizeZero;
				}
			}
		}
		return CGSizeMake(collectionView.frame.size.width, collectionView.height - contentHeight);
	}
	return CGSizeZero;
}



- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
	if (section < [self.dates count]) {
		return CGSizeMake(collectionView.frame.size.width, 32);
	} else {
		return CGSizeZero;
	}
}

- (void)handlePaginationWithIndexPath:(NSIndexPath*)indexPath {
	if (!self.shouldAppendMoreMessages) {
		return;
	}
	if (indexPath.section != [self.dates count] - 1) {
		return;
	}
	WLWrapDate* date = [self.dates objectAtIndex:indexPath.section];
	if (indexPath.row == [date.candies count] - 1) {
		[self appendMessages];
	}
}

@end
