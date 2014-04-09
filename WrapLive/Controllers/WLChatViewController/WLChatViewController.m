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

@interface WLChatViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray* messages;

@property (nonatomic, weak) WLRefresher* refresher;

@property (nonatomic) BOOL shouldAppendMoreMessages;

@property (nonatomic, strong) IBOutlet UIView* loadingView;

@property (nonatomic, weak) IBOutlet UITableView* tableView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@end

@implementation WLChatViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", self.wrap.name];
	
	__weak typeof(self)weakSelf = self;
	self.refresher = [WLRefresher refresherWithScrollView:self.tableView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf refreshMessages];
	}];
	self.tableView.transform = CGAffineTransformMakeRotation(M_PI);
	
	[self refreshMessages];
}

- (void)setShouldAppendMoreMessages:(BOOL)shouldAppendMoreMessages {
	_shouldAppendMoreMessages = shouldAppendMoreMessages;
	self.tableView.tableFooterView = shouldAppendMoreMessages ? self.loadingView : nil;
}

- (NSMutableArray *)messages {
	if (!_messages) {
		_messages = [NSMutableArray array];
	}
	return _messages;
}

- (void)refreshMessages {
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] chatMessages:self.wrap
									 page:1
								  success:^(id object) {
		[weakSelf.messages setArray:object];
		[weakSelf reloadTableView];
		[weakSelf.refresher endRefreshing];
	} failure:^(NSError *error) {
		[error show];
		[weakSelf.refresher endRefreshing];
	}];
}

- (void)appendMessages {
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] chatMessages:self.wrap
									 page:floorf([self.messages count] / 10) + 1
								  success:^(id object) {
		[weakSelf.messages addObjectsFromArray:object];
		[weakSelf reloadTableView];
	} failure:^(NSError *error) {
		[error show];
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
	headerView.height = inset;
	tableView.tableHeaderView = headerView;
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
		[weakSelf.messages insertObject:object atIndex:0];
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

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLCandy* comment = [self.messages objectAtIndex:indexPath.row];
	BOOL isMyComment = [comment.contributor isCurrentUser];
	NSString* cellIdentifier = isMyComment ? @"WLMyMessageCell" : @"WLMessageCell";
	WLMessageCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];;
	cell.item = comment;
	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.transform = CGAffineTransformMakeRotation(M_PI);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLCandy* comment = [self.messages objectAtIndex:indexPath.row];
	CGFloat commentHeight  = ceilf([comment.chatMessage boundingRectWithSize:CGSizeMake(255, CGFLOAT_MAX)
															  options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont lightMicroFont]} context:nil].size.height);
	CGFloat cellHeight = [comment.contributor isCurrentUser] ? commentHeight  : (commentHeight + 20);
	return MAX(44, cellHeight);
}

@end
