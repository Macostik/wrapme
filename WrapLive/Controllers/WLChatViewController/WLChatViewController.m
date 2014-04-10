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

@interface WLChatViewController () <UITableViewDataSource, UITableViewDelegate, WLComposeBarDelegate>

@property (nonatomic, strong) NSMutableArray* dates;

@property (nonatomic, weak) WLRefresher* refresher;

@property (nonatomic) BOOL shouldAppendMoreMessages;

@property (nonatomic, weak) IBOutlet UITableView* tableView;

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
	self.refresher = [WLRefresher refresherWithScrollView:self.tableView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf refreshMessages];
	}];
	self.refresher.colorScheme = WLRefresherColorSchemeOrange;
	self.tableView.transform = CGAffineTransformMakeRotation(M_PI);
	
	[self refreshMessages];
	
	self.tableView.tableFooterView = [WLLoadingView instance];
	
	[self.tableView registerNib:[WLMessageGroupCell nib] forHeaderFooterViewReuseIdentifier:[WLMessageGroupCell reuseIdentifier]];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if (self.shouldShowKeyboard) {
		[self.composeBar becomeFirstResponder];
	}
}

- (void)setShouldAppendMoreMessages:(BOOL)shouldAppendMoreMessages {
	_shouldAppendMoreMessages = shouldAppendMoreMessages;
	self.tableView.tableFooterView = shouldAppendMoreMessages ? [WLLoadingView instance] : nil;
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
	
	[self reloadTableView];
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

- (void)reloadTableView {
	[self.tableView reloadData];
	[self updateInsetView];
}

- (void)updateInsetView {
	UITableView* tableView = self.tableView;
	UIView* headerView = tableView.tableHeaderView;
	CGFloat contentHeight = (tableView.contentSize.height - headerView.height);
	CGFloat inset = 0;
	if (contentHeight < tableView.height) {
		inset = tableView.height - contentHeight;
	}
	if (headerView.height != inset) {
		headerView.height = inset;
		tableView.tableHeaderView = headerView;
	}
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - WLComposeBarDelegate

- (void)sendMessageWithText:(NSString*)text {
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] addCandy:[WLCandy chatMessageWithText:text]
							   toWrap:self.wrap
							  success:^(id object) {
		[weakSelf insertMessage:object];
		[weakSelf.wrap postNotificationForRequest:YES];
		[weakSelf reloadTableView];
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
	self.tableView.height = self.view.height - self.topView.height - self.composeBar.height - 216;
	self.composeBar.y = CGRectGetMaxY(self.tableView.frame);
	[self updateInsetView];
}

- (void)composeBarDidEndEditing:(WLComposeBar *)composeBar {
	self.tableView.height = self.view.height - self.topView.height - self.composeBar.height;
	self.composeBar.y = CGRectGetMaxY(self.tableView.frame);
	[self updateInsetView];
}

- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar *)composeBar {
	return NO;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.dates count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	WLWrapDate* date = [self.dates objectAtIndex:section];
	return [date.candies count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLWrapDate* date = [self.dates objectAtIndex:indexPath.section];
	WLCandy* message = [date.candies objectAtIndex:indexPath.row];
	BOOL isMyComment = [message.contributor isCurrentUser];
	NSString* cellIdentifier = isMyComment ? @"WLMyMessageCell" : @"WLMessageCell";
	WLMessageCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];;
	cell.item = message;
	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.transform = CGAffineTransformMakeRotation(M_PI);
	[self handlePaginationWithIndexPath:indexPath];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLWrapDate* date = [self.dates objectAtIndex:indexPath.section];
	WLCandy* comment = [date.candies objectAtIndex:indexPath.row];
	CGFloat commentHeight  = ceilf([comment.chatMessage boundingRectWithSize:CGSizeMake(255, CGFLOAT_MAX)
															  options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont lightMicroFont]} context:nil].size.height);
	CGFloat cellHeight = [comment.contributor isCurrentUser] ? commentHeight  : (commentHeight + 20);
	return MAX(44, cellHeight);
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	WLMessageGroupCell* groupCell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[WLMessageGroupCell reuseIdentifier]];
	groupCell.date = [self.dates objectAtIndex:section];
	groupCell.transform = CGAffineTransformMakeRotation(M_PI);
	return groupCell;
}

@end
