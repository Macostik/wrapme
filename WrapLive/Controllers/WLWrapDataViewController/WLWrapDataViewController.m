//
//  WLWrapDataViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapDataViewController.h"
#import "WLCommentCell.h"
#import "WLCandy.h"
#import "NSDate+Formatting.h"
#import "UIImageView+ImageLoading.h"
#import "UIView+Shorthand.h"
#import "WLUser.h"
#import "WLComposeContainer.h"
#import "WLComposeBar.h"
#import "WLComment.h"
#import "WLSession.h"
#import "WLAPIManager.h"
#import "WLWrap.h"
#import "UIFont+CustomFonts.h"
#import "WLRefresher.h"

static CGFloat WLDefaultImageWidth = 320;
static NSString* WLCommentCellIdentifier = @"WLCommentCell";

@interface WLWrapDataViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLComposeBarDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBarView;

@property (weak, nonatomic) WLRefresher *refresher;

@end

@implementation WLWrapDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	[self setupImage:self.candy];
	[self refresh];
	self.composeBarView.placeholder = @"Write your comment ...";
	__weak typeof(self)weakSelf = self;
	self.refresher = [WLRefresher refresherWithScrollView:self.tableView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf refresh];
	}];
	self.refresher.colorScheme = WLRefresherColorSchemeWhite;
	
	self.backSwipeGestureEnabled = YES;
}

- (void)refresh {
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] candyInfo:self.candy forWrap:self.wrap success:^(WLCandy * object) {
		[weakSelf.tableView reloadData];
		[weakSelf.refresher endRefreshing];
	} failure:^(NSError *error) {
		[error show];
		[weakSelf.refresher endRefreshing];
	}];
}

- (void)setupImage:(WLCandy*)image {
	__weak typeof(self)weakSelf = self;
	[self.imageView setImageUrl:image.picture.large completion:^(UIImage* image, BOOL cached) {
		[weakSelf.spinner removeFromSuperview];
		CGFloat height = image.size.height*WLDefaultImageWidth/image.size.width;
		[weakSelf setTableHeaderViewHeight:MIN(WLDefaultImageWidth, height) animated:!cached];
	}];
	self.titleLabel.text = [NSString stringWithFormat:@"By %@", image.contributor.name];
}

- (void)setTableHeaderViewHeight:(CGFloat)height animated:(BOOL)animated {
	UIView* headerView = self.tableView.tableHeaderView;
	if (headerView.height != height) {
		if (animated) {
			[UIView beginAnimations:nil context:nil];
		}
		headerView.height = height;
		self.tableView.tableHeaderView = headerView;
		if (animated) {
			[UIView commitAnimations];
		}
	}
}

- (CGFloat)calculateTableHeight {
	return (self.view.height - self.composeBarView.height - self.topView.height);
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)toggleImage:(id)sender {
	CGFloat height = self.tableView.tableHeaderView.height;
	UIImage* image = self.imageView.image;
	if (height == WLDefaultImageWidth && image) {
		height = image.size.height*WLDefaultImageWidth/image.size.width;
	} else {
		height = WLDefaultImageWidth;
	}
	[self setTableHeaderViewHeight:height animated:YES];
}

- (void)sendMessageWithText:(NSString*)text {
	__weak typeof(self)weakSelf = self;
	WLComment* comment = [WLComment commentWithText:text];
	[[WLAPIManager instance] addComment:comment toCandy:self.candy fromWrap:self.wrap success:^(id object) {
		[weakSelf.tableView reloadData];
		[weakSelf.wrap broadcastChange];
		if (weakSelf.tableView.contentSize.height > [weakSelf calculateTableHeight]) {
			[weakSelf.tableView setContentOffset:CGPointMake(0, weakSelf.tableView.contentSize.height - weakSelf.tableView.height) animated:NO];
		}
	} failure:^(NSError *error) {
		[error show];
	}];
}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[self sendMessageWithText:text];
}

- (void)composeBarDidReturn:(WLComposeBar *)composeBar {
	[composeBar resignFirstResponder];
}

- (void)composeBarDidBeginEditing:(WLComposeBar *)composeBar {
	self.containerView.frame = CGRectMake(self.containerView.x, self.containerView.y, self.containerView.width, self.view.height - self.topView.height - 216);
	if (self.tableView.contentSize.height > [self calculateTableHeight]) {
		[self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y + 216) animated:NO];
	} else {
		[self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y + 216 - ([self calculateTableHeight] - self.tableView.contentSize.height)) animated:NO];
	}
}

- (void)composeBarDidEndEditing:(WLComposeBar *)composeBar {
	self.containerView.frame = CGRectMake(self.containerView.x, self.containerView.y, self.containerView.width, self.view.height - self.topView.height);
	if (self.tableView.contentSize.height > [self calculateTableHeight]) {
		[self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - self.tableView.height) animated:NO];
	}
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.candy.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLComment* comment = [self.candy.comments objectAtIndex:indexPath.row];
	NSString* cellIdentifier = WLCommentCellIdentifier;
	WLCommentCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	cell.item = comment;
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLComment* comment = [self.candy.comments objectAtIndex:indexPath.row];
	CGFloat commentHeight  = ceilf([comment.text boundingRectWithSize:CGSizeMake(WLCommentLabelLenth, CGFLOAT_MAX)
														 options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[WLCommentCell commentFont]} context:nil].size.height);
	CGFloat cellHeight = (commentHeight + WLAuthorLabelHeight);
	return MAX(WLMinimumCellHeight, cellHeight + 10);
}

@end
