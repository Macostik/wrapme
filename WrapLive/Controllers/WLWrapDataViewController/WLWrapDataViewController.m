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


@interface WLWrapDataViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WLComposeBarDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) NSArray * testCommentsArray;

@end

@implementation WLWrapDataViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	if ([self.candy.type isEqualToString:WLCandyTypeImage]) {
		[self setupImageView:self.candy];
		self.titleLabel.text = [NSString stringWithFormat:@"By %@", self.candy.author.name];
	}
	else {
		self.titleLabel.text = [self.candy.updatedAt stringWithFormat:@"MMMM dd, YYYY"];
		self.imageView.height = 0;
	}
	
	WLComment * comment1 = [[WLComment alloc] init];
	comment1.text = @"Comment 1";
	WLComment * comment2 = [[WLComment alloc] init];
	comment2.text = @"Comment 2";
	WLComment * comment3 = [[WLComment alloc] init];
	comment3.text = @"Comment 3";
	WLComment * comment4 = [[WLComment alloc] init];
	comment4.text = @"Comment 4";
	self.testCommentsArray = @[comment1, comment2, comment3, comment4];
}

- (void)setupImageView:(WLCandy *)image {
	self.imageView.height = 320;
	self.imageView.imageUrl = image.picture.large;
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)sendMessage {

}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[self sendMessage];
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

#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self sendMessage];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	CGFloat translation = 216;
	CGAffineTransform transform = CGAffineTransformMakeTranslation(0, -translation);
	[UIView animateWithDuration:0.5 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.view.transform = transform;
	} completion:^(BOOL finished) {}];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.view.transform = CGAffineTransformIdentity;
	} completion:^(BOOL finished) {}];
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.testCommentsArray.count;
//	return self.candy.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString* wrapCellIdentifier = @"WLCommentCell";
	WLCommentCell* cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier
													   forIndexPath:indexPath];
	cell.item = [self.testCommentsArray objectAtIndex:indexPath.row];
//	cell.item = [self.candy.comments objectAtIndex:indexPath.row];
	return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self.view endEditing:YES];
}

@end
