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
#import "WLUploadingQueue.h"
#import "WLCollectionViewFlowLayout.h"
#import "UIScrollView+Additions.h"
#import "WLKeyboardBroadcaster.h"
#import "WLDataManager.h"
#import "NSDate+Additions.h"
#import "NSString+Additions.h"
#import "WLBlocks.h"
#import "WLEntryState.h"
#import "WLWrapBroadcaster.h"

@interface WLChatViewController () <UICollectionViewDataSource, UICollectionViewDelegate, WLComposeBarDelegate, UICollectionViewDelegateFlowLayout, WLKeyboardBroadcastReceiver, WLWrapBroadcastReceiver>

@property (nonatomic, strong) NSMutableArray* dates;

@property (nonatomic, weak) WLRefresher* refresher;

@property (nonatomic) BOOL shouldAppendMoreMessages;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@property (nonatomic, readonly) WLCollectionViewFlowLayout* layout;

@property (nonatomic) CGFloat keyboardHeight;

@end

@implementation WLChatViewController
{
	BOOL loading;
	NSInteger messagesCount;
}

- (WLCollectionViewFlowLayout *)layout {
	return (WLCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if (self.wrap.name.nonempty) {
		self.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", WLString(self.wrap.name)];
	} else {
		__weak typeof(self)weakSelf = self;
		[self.wrap fetch:^(WLWrap *wrap) {
			weakSelf.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", WLString(wrap.name)];
		} failure:^(NSError *error) {
		}];
	}
	__weak typeof(self)weakSelf = self;
	self.refresher = [WLRefresher refresherWithScrollView:self.collectionView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf refreshMessages];
	}];
	self.refresher.colorScheme = WLRefresherColorSchemeOrange;
	self.collectionView.transform = CGAffineTransformMakeRotation(M_PI);
	self.composeBar.placeholder = @"Write your message ...";
	
	run_getting_object(^id{
		return [weakSelf.wrap messages];
	}, ^(id object) {
		[weakSelf setMessages:object];
		[weakSelf refreshMessages];
	});
	
	self.backSwipeGestureEnabled = YES;
	
	[[WLKeyboardBroadcaster broadcaster] addReceiver:self];
    [[WLWrapBroadcaster broadcaster] addReceiver:self];
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
	while (_messages.nonempty) {
		WLCandy* candy = [_messages firstObject];
		NSArray* dayMessages = [_messages entriesForDay:candy.updatedAt];
		[self addMessages:dayMessages date:candy.updatedAt];
		[_messages removeObjectsInArray:dayMessages];
	}
	
	self.shouldAppendMoreMessages = ([messages count] == WLAPIChatPageSize);
	
	[self.collectionView reloadData];
}

- (void)addMessages:(NSArray*)messages date:(NSDate*)date {
	WLWrapDate* dateObject = [self dateObjectWithDate:date];
	dateObject.candies = (id)[dateObject.candies entriesByAddingEntries:messages];
}

- (void)insertMessage:(WLCandy*)message {
	WLWrapDate* dateObject = [self dateObjectWithDate:message.updatedAt];
	dateObject.candies = (id)[dateObject.candies entriesByInsertingFirstEntry:message];
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
	[self.dates sortEntriesByUpdatingDate];
	return dateObject;
}

- (void)refreshMessages {
	__weak typeof(self)weakSelf = self;
	[WLDataManager messages:self.wrap success:^(id object, BOOL cached, BOOL stop) {
		weakSelf.shouldAppendMoreMessages = [object count] == WLAPIChatPageSize;
		[weakSelf setMessages:object];
		[weakSelf.refresher endRefreshing];
	} failure:^(NSError *error) {
		weakSelf.shouldAppendMoreMessages = NO;
		[error showIgnoringNetworkError];
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
	[[WLAPIManager instance] messages:self.wrap page:page success:^(id object) {
		weakSelf.shouldAppendMoreMessages = [object count] == WLAPIChatPageSize;
		[weakSelf addMessages:object];
		loading = NO;
	} failure:^(NSError *error) {
		weakSelf.shouldAppendMoreMessages = NO;
		[error showIgnoringNetworkError];
		loading = NO;
	}];
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyCreated:(WLCandy *)candy {
    if ([candy belongsToWrap:self.wrap] && [candy isChatMessage]) {
        [candy setUpdated:NO];
        [self insertMessage:candy];
        [self.collectionView reloadData];
    }
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

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - WLComposeBarDelegate

- (void)sendMessageWithText:(NSString*)text {
	__weak typeof(self)weakSelf = self;
	[[WLUploadingQueue instance] uploadMessage:text wrap:self.wrap success:^(id object) {
		[weakSelf insertMessage:object];
		[weakSelf.collectionView reloadData];
		[weakSelf.collectionView scrollToTopAnimated:YES];
	} failure:^(NSError *error) {
	}];
}

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
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
	return YES;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return [self.dates count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	WLWrapDate* date = [self.dates objectAtIndex:section];
	return [date.candies count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	WLWrapDate* date = [self.dates objectAtIndex:indexPath.section];
	WLCandy* message = [date.candies objectAtIndex:indexPath.row];
	[message setUpdated:NO];
	BOOL isMyComment = [message.contributor isCurrentUser];
	NSString* cellIdentifier = isMyComment ? @"WLMyMessageCell" : @"WLMessageCell";
	WLMessageCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
	cell.item = message;
	[self handlePaginationWithIndexPath:indexPath];
	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	WLMessageGroupCell* groupCell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"WLMessageGroupCell" forIndexPath:indexPath];
	groupCell.date = [self.dates objectAtIndex:indexPath.section];
	return groupCell;
}

- (CGFloat)heightOfMessageCell:(WLCandy *)comment {
	CGFloat commentHeight  = ceilf([comment.chatMessage boundingRectWithSize:CGSizeMake(250, CGFLOAT_MAX)
																	 options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont lightFontOfSize:15]} context:nil].size.height);
	commentHeight += WLMessageAuthorLabelHeight;
	return MAX(WLMessageMinimumCellHeight, commentHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	WLWrapDate* date = [self.dates objectAtIndex:indexPath.section];
	WLCandy* comment = [date.candies objectAtIndex:indexPath.row];
	return CGSizeMake(collectionView.frame.size.width, [self heightOfMessageCell:comment]);
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
