//
//  WLWrapDataViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandyViewController.h"
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
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "UIStoryboard+Additions.h"
#import "WLImageViewController.h"

static CGFloat WLDefaultImageWidth = 320;
static NSString* WLCommentCellIdentifier = @"WLCommentCell";

@interface WLCandyViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLComposeBarDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBarView;

@property (weak, nonatomic) WLRefresher *refresher;

@end

@implementation WLCandyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	self.composeBarView.placeholder = @"Write your comment ...";
	__weak typeof(self)weakSelf = self;
	self.refresher = [WLRefresher refresherWithScrollView:self.tableView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf refresh];
	}];
	self.refresher.colorScheme = WLRefresherColorSchemeWhite;
}

- (UIView *)swipeView {
	return self.tableView;
}

- (void)setWrap:(WLWrap *)wrap candy:(WLCandy *)candy {
	self.wrap = wrap;
	[self setItems:[wrap getAllImages] currentItem:candy];
}

- (void)setCandy:(WLCandy *)candy  {
	self.item = candy;
}

- (WLCandy *)candy {
	return self.item;
}

- (void)willShowItem:(id)item {
	[self setupImage];
	[self refresh];
}

- (void)refresh {
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] candyInfo:self.candy forWrap:self.wrap success:^(WLCandy * object) {
		[weakSelf setupImage];
		[weakSelf.refresher endRefreshing];
	} failure:^(NSError *error) {
		[error show];
		[weakSelf.refresher endRefreshing];
	}];
}

- (void)setupImage {
	WLCandy* image = self.candy;
	__weak typeof(self)weakSelf = self;
	if (!self.spinner.isAnimating) {
		[self.spinner startAnimating];
	}
	[self.imageView setImageUrl:image.picture.medium completion:^(UIImage* image, BOOL cached) {
		if (weakSelf.spinner.isAnimating) {
			[weakSelf.spinner stopAnimating];
		}
	}];
	self.titleLabel.text = [NSString stringWithFormat:@"By %@", image.contributor.name];
	[self.tableView reloadData];
}

- (CGFloat)calculateTableHeight {
	return (self.view.height - self.composeBarView.height - self.topView.height);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isImageSegue]) {
		WLImageViewController* controller = segue.destinationViewController;
		controller.image = self.candy;
	}
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
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
