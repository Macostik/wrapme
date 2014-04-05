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

@interface WLWrapDataViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLComposeBarDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation WLWrapDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	if (self.candy.type == WLCandyTypeImage) {
		[self setupImageView:self.candy];
		self.titleLabel.text = [NSString stringWithFormat:@"By %@", self.candy.contributor.name];
	} else {
		self.titleLabel.text = [NSString stringWithFormat:@"Chat in %@", self.wrap.name];
		self.imageView.height = 0;
	}
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] candyInfo:self.candy forWrap:self.wrap success:^(WLCandy * object) {
		weakSelf.candy = object;
		[weakSelf.tableView reloadData];
	} failure:^(NSError *error) {
		
	}];
}

- (void)setupImageView:(WLCandy *)image {
	self.imageView.height = 320;
	self.imageView.imageUrl = image.picture.large;
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
		[weakSelf.wrap postNotificationForRequest:YES];
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
	[UIView animateWithDuration:0.5 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.containerView.frame = CGRectMake(self.containerView.x, self.containerView.y, self.containerView.width, self.view.height - self.topView.height - 216);
	} completion:^(BOOL finished) {}];
	
}

- (void)composeBarDidEndEditing:(WLComposeBar *)composeBar {
	[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.containerView.frame = CGRectMake(self.containerView.x, self.containerView.y, self.containerView.width, self.view.height - self.topView.height);
	} completion:^(BOOL finished) {}];
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.candy.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLCommentCell* cell = nil;
	WLComment* comment = [self.candy.comments objectAtIndex:indexPath.row];
	if (self.candy.type == WLCandyTypeConversation && [comment.contributor isCurrentUser]) {
		static NSString* wrapCellIdentifier = @"WLMyCommentCell";
		cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier
											   forIndexPath:indexPath];
	} else {
		static NSString* wrapCellIdentifier = @"WLCommentCell";
		cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier
															  forIndexPath:indexPath];
	}
	[cell configureCellHeightWithComment:comment];
	cell.item = comment;
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLComment* comment = [self.candy.comments objectAtIndex:indexPath.row];
	CGFloat commentHeight  = ceilf([comment.text boundingRectWithSize:CGSizeMake(WLCommentLabelLenth, CGFLOAT_MAX)
														 options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont lightMicroFont]} context:nil].size.height);
	CGFloat cellHeight = [comment.contributor isCurrentUser] ? commentHeight  : (commentHeight + WLAuthorLabelHeight);
	return cellHeight > WLMinimumCellHeight ? cellHeight : WLMinimumCellHeight;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self.view endEditing:YES];
}

@end
