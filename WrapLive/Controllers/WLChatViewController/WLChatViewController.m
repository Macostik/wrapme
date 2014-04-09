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

@interface WLChatViewController ()

@property (nonatomic, strong) NSMutableArray* messages;

@property (nonatomic, weak) WLRefresher* refresher;

@property (nonatomic) BOOL shouldAppendMoreMessages;

@property (nonatomic, strong) IBOutlet UIView* loadingView;

@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation WLChatViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", self.wrap.name];
	
	__weak typeof(self)weakSelf = self;
	self.refresher = [WLRefresher refresherWithScrollView:self.tableView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf refreshMessages];
	}];
	
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
	[self.messages removeAllObjects];
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] chatMessages:self.wrap
									 page:1
								  success:^(id object) {
		[weakSelf.messages addObjectsFromArray:object];
		[weakSelf.tableView reloadData];
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
		[weakSelf.tableView reloadData];
	} failure:^(NSError *error) {
		[error show];
	}];
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLCandy* comment = [self.messages objectAtIndex:indexPath.row];
	CGFloat commentHeight  = ceilf([comment.chatMessage boundingRectWithSize:CGSizeMake(255, CGFLOAT_MAX)
															  options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont lightMicroFont]} context:nil].size.height);
	CGFloat cellHeight = [comment.contributor isCurrentUser] ? commentHeight  : (commentHeight + 20);
	return MAX(44, cellHeight);
}

@end
