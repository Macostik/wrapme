//
//  WLWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapViewController.h"
#import "WLWrap.h"
#import "WLWrapCandiesCell.h"
#import "UIImageView+ImageLoading.h"
#import "WLCandy.h"
#import "NSDate+Formatting.h"
#import "WLWrapDate.h"
#import "UIView+Shorthand.h"
#import "UIStoryboard+Additions.h"
#import "WLCameraViewController.h"
#import "WLWrapDataViewController.h"
#import "WLCreateWrapViewController.h"
#import "WLComposeBar.h"
#import "WLComposeContainer.h"
#import "UIImage+WLStoring.h"
#import "WLAPIManager.h"
#import "WLProgressView.h"
#import "WLComment.h"
#import "WLRefresher.h"

@interface WLWrapViewController () <WLCameraViewControllerDelegate, WLWrapCandiesCellDelegate, WLComposeBarDelegate>

@property (strong, nonatomic) IBOutlet UITableView* tableView;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet UIView *firstContributorView;
@property (weak, nonatomic) IBOutlet UILabel *firstContributorWrapNameLabel;
@property (weak, nonatomic) IBOutlet WLComposeContainer *composeContainer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (weak, nonatomic) WLRefresher *refresher;

@end

@implementation WLWrapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.coverView.imageUrl = self.wrap.picture.thumbnail;
	self.nameLabel.text = self.wrap.name;
	__weak typeof(self)weakSelf = self;
	[self.wrap contributorNames:^(NSString *names) {
		weakSelf.contributorsLabel.text = names;
	}];
		
	[self refreshWrap];
	
	self.refresher = [WLRefresher refresherWithScrollView:self.tableView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf refreshWrap];
	}];
}

- (void)refreshWrap {
	__weak typeof(self)weakSelf = self;
	WLWrap* wrap = [self.wrap copy];
	wrap.dates = nil;
	[[WLAPIManager instance] wrap:wrap success:^(WLWrap* wrap) {
		if ([wrap.dates count] == 0) {
			weakSelf.firstContributorView.alpha = 1.0f;
			weakSelf.firstContributorWrapNameLabel.text = wrap.name;
		}
		[weakSelf.wrap updateWithObject:wrap];
		[weakSelf.tableView reloadData];
		[weakSelf.refresher endRefreshing];
		[weakSelf.spinner removeFromSuperview];
	} failure:^(NSError *error) {
		[error show];
		[weakSelf.refresher endRefreshing];
		[weakSelf.spinner removeFromSuperview];
	}];
}

- (UIViewController *)shakePresentedViewController {
	return [self cameraViewController];
}

- (WLCameraViewController*)cameraViewController {
	WLCameraViewController* cameraController = [self.storyboard cameraViewController];
	cameraController.delegate = self;
	cameraController.mode = WLCameraModeFullSize;
	cameraController.backfacingByDefault = YES;
	return cameraController;
}

- (IBAction)typeMessage:(UIButton *)sender {
	[self.composeContainer setEditing:!self.composeContainer.editing animated:YES];
}

- (void)sendMessageWithText:(NSString*)text {
	/*
	[[WLAPIManager instance] addComment:[WLComment commentWithText:text] toCandy:nil fromWrap:self.wrap success:^(id object) {
		
	} failure:^(NSError *error) {
		[error show];
	}];
	 404 Not Found  responce (waiting API)
	 */
	[[self.wrap actualConversation] addCommentWithText:text];
}

#pragma mark - User Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isCameraSegue]) {
		WLCameraViewController* cameraController = segue.destinationViewController;
		cameraController.mode = WLCameraModeFullSize;
		cameraController.delegate = self;
		cameraController.backfacingByDefault = YES;
		[UIView beginAnimations:nil context:nil];
		self.firstContributorView.alpha = 0.0f;
		[UIView commitAnimations];
	} else if ([segue isChangeWrapSegue]) {
		WLCreateWrapViewController * createWrapController = segue.destinationViewController;
		createWrapController.wrap = self.wrap;
	}
}

- (IBAction)notNow:(UIButton *)sender {
	[UIView beginAnimations:nil context:nil];
	self.firstContributorView.alpha = 0.0f;
	[UIView commitAnimations];
}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[self.composeContainer setEditing:NO animated:YES];
	[self sendMessageWithText:text];
}

- (void)composeBarDidReturn:(WLComposeBar *)composeBar {
	[self.composeContainer setEditing:NO animated:YES];
}

#pragma mark - WLWrapCandiesCellDelegate

- (void)wrapCandiesCell:(WLWrapCandiesCell*)cell didSelectCandy:(WLCandy*)candy {
	WLWrapDataViewController * wrapDatacontroller = [self.storyboard wrapDataViewController];
	wrapDatacontroller.candy = candy;
	wrapDatacontroller.wrap = self.wrap;
	[self.navigationController pushViewController:wrapDatacontroller animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.wrap.dates count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLWrapCandiesCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLWrapCandiesCell reuseIdentifier]];
	cell.item = [self.wrap.dates objectAtIndex:indexPath.row];
	cell.wrap = self.wrap;
	cell.delegate = self;
    return cell;
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	__weak typeof(self)weakSelf = self;
	
	[WLProgressView showWithMessage:@"Uploading image..." image:image operation:nil];
	
	[image storeAsImage:^(NSString *path) {
		WLCandy* candy = [WLCandy entry];
		candy.type = WLCandyTypeImage;
		candy.picture.large = path;
		id operation = [[WLAPIManager instance] addCandy:candy toWrap:weakSelf.wrap success:^(id object) {
			[weakSelf.wrap postNotificationForRequest:YES];
			[weakSelf.tableView reloadData];
			[WLProgressView dismiss];
		} failure:^(NSError *error) {
			[WLProgressView dismiss];
			[error show];
		}];
		[WLProgressView setOperation:operation];
	}];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
