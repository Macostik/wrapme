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
#import "WLImage.h"
#import "UIImageView+ImageLoading.h"
#import "UIView+Shorthand.h"
#import "WLUser.h"
#import "WLPicture.h"

@interface WLWrapDataViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *messageView;
@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation WLWrapDataViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	if ([self.candy.type isEqualToString:WLCandyTypeImage]) {
		[self setupImageView:(WLImage*)self.candy];
		self.titleLabel.text = [NSString stringWithFormat:@"By %@", self.candy.author.name];
	}
	else {
		self.titleLabel.text = [self.candy.updatedAt stringWithFormat:@"MMMM dd, YYYY"];
		self.imageView.height = 0;
	}
}

- (void)setupImageView:(WLImage *)image {
	self.imageView.height = 320;
	self.imageView.imageUrl = image.url.large;
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)sendMessage:(UIButton *)sender {
	[self sendMessage];
}

- (IBAction)messageChanged:(UITextField *)sender {
	self.sendMessageButton.enabled = sender.text.length > 0;
}

- (void)sendMessage {
	[self.view endEditing:YES];
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
	return self.candy.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString* wrapCellIdentifier = @"WLCommentCell";
	WLCommentCell* cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier
													   forIndexPath:indexPath];
	cell.item = [self.candy.comments objectAtIndex:indexPath.row];
	return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self.view endEditing:YES];
}

@end
