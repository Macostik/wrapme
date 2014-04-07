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
#import "WLWrapDay.h"
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

@interface WLWrapViewController () <WLCameraViewControllerDelegate, WLWrapCandiesCellDelegate, WLComposeBarDelegate>

@property (strong, nonatomic) IBOutlet UITableView* tableView;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (strong, nonatomic) NSMutableArray * wrapDays;
@property (weak, nonatomic) IBOutlet UIView *firstContributorView;
@property (weak, nonatomic) IBOutlet UILabel *firstContributorWrapNameLabel;
@property (weak, nonatomic) IBOutlet WLComposeContainer *composeContainer;

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
	
	[self sortCandiesInWrap];
	
	if ([self.wrap.candies count] == 0) {
		self.firstContributorView.alpha = 1.0f;
		self.firstContributorWrapNameLabel.text = self.wrap.name;
	}
}

- (void) sortCandiesInWrap {
	NSMutableArray* candies = [self.wrap.candies mutableCopy];
	
	NSMutableArray* wrapDays = [NSMutableArray array];
	
	while ([candies count] > 0) {
		WLCandy* candy = [candies firstObject];
		NSArray *dayCandies = [WLWrap candiesForDate:candy.updatedAt inArray:candies];
		WLWrapDay * wrapDay = [WLWrapDay new];
		wrapDay.updatedAt = candy.updatedAt;
		wrapDay.candies = dayCandies;
		[wrapDays addObject:wrapDay];
		[candies removeObjectsInArray:dayCandies];
	}

	[wrapDays sortEntries];
	
	self.wrapDays = [wrapDays copy];
	
	[self.tableView reloadData];
}

- (IBAction)typeMessage:(UIButton *)sender {
	[self.composeContainer setEditing:!self.composeContainer.editing animated:YES];
}

- (void)sendMessageWithText:(NSString*)text {
	[[self.wrap actualConversation] addCommentWithText:text];
	[self sortCandiesInWrap];
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
    return self.wrapDays.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLWrapCandiesCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLWrapCandiesCell reuseIdentifier]];
	cell.item = [self.wrapDays objectAtIndex:indexPath.row];
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
			[weakSelf sortCandiesInWrap];
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
