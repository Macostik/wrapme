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
	
	if ([self.candy.type isEqualToString:WLCandyTypeImage]) {
		[self setupImageView:self.candy];
		self.titleLabel.text = [NSString stringWithFormat:@"By %@", self.candy.author.name];
	} else {
		self.titleLabel.text = [self.candy.updatedAt stringWithFormat:@"MMMM dd, YYYY"];
		self.imageView.height = 0;
	}
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
	} failure:^(NSError *error) {
		[error show];
	}];
}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[self sendMessageWithText:text];
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
	if ([self.candy.type isEqualToString:WLCandyTypeConversation] && [comment.author isCurrentUser]) {
		static NSString* wrapCellIdentifier = @"WLMyCommentCell";
		cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier
											   forIndexPath:indexPath];
	} else {
		static NSString* wrapCellIdentifier = @"WLCommentCell";
		cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier
															  forIndexPath:indexPath];
	}
	cell.item = comment;
	return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self.view endEditing:YES];
}

@end
