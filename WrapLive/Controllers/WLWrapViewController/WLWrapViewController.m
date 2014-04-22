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
#import "WLCandyViewController.h"
#import "WLCreateWrapViewController.h"
#import "WLComposeBar.h"
#import "WLComposeContainer.h"
#import "UIImage+WLStoring.h"
#import "WLAPIManager.h"
#import "WLComment.h"
#import "WLRefresher.h"
#import "WLChatViewController.h"
#import "WLLoadingView.h"
#import "WLWrapBroadcaster.h"
#import "WLUploadingQueue.h"

@interface WLWrapViewController () <WLCameraViewControllerDelegate, WLWrapCandiesCellDelegate, WLComposeBarDelegate, WLWrapBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UITableView* tableView;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet UIView *firstContributorView;
@property (weak, nonatomic) IBOutlet UILabel *firstContributorWrapNameLabel;
@property (weak, nonatomic) IBOutlet WLComposeContainer *composeContainer;
@property (nonatomic) BOOL shouldLoadMoreDates;

@property (weak, nonatomic) WLRefresher *refresher;

@end

@implementation WLWrapViewController
{
	BOOL loading;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[self setWrapData];
		
	[self refreshWrap];
	__weak typeof(self)weakSelf = self;
	self.refresher = [WLRefresher refresherWithScrollView:self.tableView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf refreshWrap];
	}];
	self.refresher.colorScheme = WLRefresherColorSchemeOrange;
	
	self.tableView.tableFooterView = [WLLoadingView instance];
	
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self.composeContainer setEditing:NO];
	[super viewWillDisappear:animated];
}

- (void)setWrapData {
	self.coverView.imageUrl = self.wrap.picture.thumbnail;
	self.nameLabel.text = self.wrap.name;
	__weak typeof(self)weakSelf = self;
	[self.wrap contributorNames:^(NSString *names) {
		weakSelf.contributorsLabel.text = names;
		weakSelf.contributorsLabel.height = MIN(34, [weakSelf.contributorsLabel sizeThatFits:CGSizeMake(weakSelf.contributorsLabel.width, CGFLOAT_MAX)].height);
	}];
}

#pragma mark - WLWrapBroadcastReceiver

- (void)wrapBroadcaster:(WLWrapBroadcaster *)broadcaster wrapChanged:(WLWrap *)wrap {
	if ([wrap isEqualToWrap:self.wrap]) {
		[self setWrapData];
		[self.tableView reloadData];
	}
}

- (void)setShouldLoadMoreDates:(BOOL)shouldLoadMoreDates {
	_shouldLoadMoreDates = shouldLoadMoreDates;
	self.tableView.tableFooterView = shouldLoadMoreDates ? [WLLoadingView instance] : nil;
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
		weakSelf.shouldLoadMoreDates = ([wrap.dates count] == WLAPIGeneralPageSize);
		[weakSelf.wrap updateWithObject:wrap];
		[[WLUploadingQueue instance] updateWrap:weakSelf.wrap];
		[weakSelf.tableView reloadData];
		[weakSelf.refresher endRefreshing];
	} failure:^(NSError *error) {
		weakSelf.shouldLoadMoreDates = NO;
		[error show];
		[weakSelf.refresher endRefreshing];
	}];
}

- (void)appendDates {
	if (loading){
		return;
	}
	loading = YES;
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] wrap:[self.wrap copy] success:^(WLWrap* wrap) {
		weakSelf.wrap.dates = (id)[weakSelf.wrap.dates arrayByAddingObjectsFromArray:wrap.dates];
		weakSelf.shouldLoadMoreDates = ([wrap.dates count] == WLAPIGeneralPageSize);
		[weakSelf.tableView reloadData];
		loading = NO;
	} failure:^(NSError *error) {
		weakSelf.shouldLoadMoreDates = NO;
		[error show];
		loading = NO;
	}];
}

- (UIViewController *)shakePresentedViewController {
	return [self cameraViewController];
}

- (WLCameraViewController*)cameraViewController {
	WLCameraViewController* cameraController = [self.storyboard cameraViewController];
	cameraController.delegate = self;
	cameraController.mode = WLCameraModeFullSize;
	return cameraController;
}

- (IBAction)typeMessage:(UIButton *)sender {
	[self.composeContainer setEditing:!self.composeContainer.editing animated:YES];
}

- (void)sendMessageWithText:(NSString*)text {
	[[WLUploadingQueue instance] uploadMessage:text wrap:self.wrap success:^(id object) {
	} failure:^(NSError *error) {
		[error show];
	}];
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
	if (candy.type == WLCandyTypeImage) {
		WLCandyViewController *controller = [self.storyboard wrapDataViewController];
		[controller setWrap:self.wrap candy:candy];
		[self.navigationController pushViewController:controller animated:YES];
	} else if (candy.type == WLCandyTypeChatMessage) {
		WLChatViewController * chatController = [self.storyboard chatViewController];
		chatController.wrap = self.wrap;
		[self.navigationController pushViewController:chatController animated:YES];
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.wrap.dates count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLWrapCandiesCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLWrapCandiesCell reuseIdentifier]];
	
	WLWrapDate* date = [self.wrap.dates objectAtIndex:indexPath.row];
	
	cell.item = date;
	cell.wrap = self.wrap;
	cell.delegate = self;
	
	if (date == [self.wrap.dates lastObject] && self.shouldLoadMoreDates) {
		[self appendDates];
	}
	
    return cell;
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	self.firstContributorView.alpha = 0.0f;
	[[WLUploadingQueue instance] uploadImage:image wrap:self.wrap success:^(id object) {
	} failure:^(NSError *error) {
		[error show];
	}];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
