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
#import "WLAPIManager.h"
#import "WLComment.h"
#import "WLRefresher.h"
#import "WLChatViewController.h"
#import "WLLoadingView.h"
#import "WLWrapBroadcaster.h"
#import "WLUploadingQueue.h"
#import "UILabel+Additions.h"
#import "WLDataManager.h"
#import "WLDataCache.h"

@interface WLWrapViewController () <WLCameraViewControllerDelegate, WLWrapCandiesCellDelegate, WLWrapBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UITableView* tableView;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet UIView *firstContributorView;
@property (weak, nonatomic) IBOutlet UILabel *firstContributorWrapNameLabel;
@property (nonatomic) BOOL shouldLoadMoreDates;

@property (weak, nonatomic) WLRefresher *refresher;
@property (strong, nonatomic) NSArray *theChannels;
@property (weak, nonatomic) IBOutlet UIImageView *shakingHandView;

@end

@implementation WLWrapViewController
{
	BOOL loading;
	BOOL wrapEditing;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[[WLUploadingQueue instance] updateWrap:self.wrap];
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

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	wrapEditing = NO;
}

- (void)setWrapData {
	self.coverView.imageUrl = self.wrap.picture.small;
	self.nameLabel.text = self.wrap.name;
	self.contributorsLabel.text = self.wrap.contributorNames;
	[self.contributorsLabel sizeToFitHeightWithMaximumHeightToSuperviewBottom];
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapChanged:(WLWrap *)wrap {
	if ([wrap isEqualToEntry:self.wrap]) {
		[self setWrapData];
		[self.tableView reloadData];
	}
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyRemoved:(WLCandy *)candy {
	for (WLWrapDate* date in self.wrap.dates) {
		if ([date.candies count] == 0) {
			self.wrap.dates = (id)[self.wrap.dates arrayByRemovingObject:date];
			[self.tableView reloadData];
			break;
		}
	}
	[[WLDataCache cache] setWrap:self.wrap];
}

- (void)setShouldLoadMoreDates:(BOOL)shouldLoadMoreDates {
	_shouldLoadMoreDates = shouldLoadMoreDates;
	self.tableView.tableFooterView = shouldLoadMoreDates ? [WLLoadingView instance] : nil;
}

- (void)refreshWrap {
	__weak typeof(self)weakSelf = self;
	[WLDataManager wrap:self.wrap success:^(WLWrap* wrap, BOOL cached, BOOL stop) {
		[[WLUploadingQueue instance] updateWrap:weakSelf.wrap];
		if (!cached) {
			if ([wrap.dates count] == 0) {
				weakSelf.firstContributorView.alpha = 1.0f;
				weakSelf.firstContributorWrapNameLabel.text = wrap.name;				
			} else {
				weakSelf.firstContributorView.alpha = 0.0f;
			}
		}
		weakSelf.shouldLoadMoreDates = !stop;
		[weakSelf.tableView reloadData];
		[weakSelf.refresher endRefreshing];
	} failure:^(NSError *error) {
		weakSelf.shouldLoadMoreDates = NO;
		[error showIgnoringNetworkError];
		[weakSelf.refresher endRefreshing];
	}];
}

- (void)animateHand {
	if (self.firstContributorView.alpha == 0) {
		return;
	}
	NSTimeInterval animationDuration = 0.3;
	CGFloat rotationAngle = M_PI * 15 / 180.0;
	CGPoint newCenter = CGPointMake(-50, 150);
	CGAffineTransform transform = CGAffineTransformMakeTranslation(newCenter.x, newCenter.y);
	transform = CGAffineTransformRotate(transform, -rotationAngle);
	transform = CGAffineTransformTranslate(transform,-newCenter.x,-newCenter.y);
	__weak typeof(self)weakSelf = self;
	[UIView animateWithDuration:animationDuration animations:^{
		[UIView setAnimationRepeatCount:1.5];
		[UIView setAnimationRepeatAutoreverses:YES];
		weakSelf.shakingHandView.transform = transform;
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:animationDuration animations:^{
			weakSelf.shakingHandView.transform = CGAffineTransformIdentity;
		} completion:^(BOOL finished) {
			[weakSelf performSelector:@selector(animateHand) withObject:nil afterDelay:5];
		}];
	}];
	
}

- (void)appendDates {
	if (loading){
		return;
	}
	loading = YES;
	__weak typeof(self)weakSelf = self;
	NSInteger page = floorf([self.wrap.dates count] / 10) + 1;
	[[WLAPIManager instance] wrap:[self.wrap copy] page:page success:^(WLWrap* wrap) {
		weakSelf.wrap.dates = (id)[weakSelf.wrap.dates arrayByAddingObjectsFromArray:wrap.dates];
		[weakSelf.tableView reloadData];
		weakSelf.shouldLoadMoreDates = ([wrap.dates count] == WLAPIGeneralPageSize);
		loading = NO;
	} failure:^(NSError *error) {
		weakSelf.shouldLoadMoreDates = NO;
		[error showIgnoringNetworkError];
		loading = NO;
	}];
}

- (UIViewController *)shakePresentedViewController {
	return [self cameraViewController];
}

- (WLCameraViewController*)cameraViewController {
	WLCameraViewController* cameraController = [self.storyboard cameraViewController];
	cameraController.delegate = self;
	cameraController.mode = WLCameraModeCandy;
	return cameraController;
}

- (IBAction)typeMessage:(UIButton *)sender {
	WLChatViewController * chatController = [self.storyboard chatViewController];
	chatController.wrap = self.wrap;
	chatController.shouldShowKeyboard = YES;
	[self.navigationController pushViewController:chatController animated:YES];
}

- (void)sendMessageWithText:(NSString*)text {
	[[WLUploadingQueue instance] uploadMessage:text wrap:self.wrap success:^(id object) {
	} failure:^(NSError *error) {
	}];
}

#pragma mark - User Actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isCameraSegue]) {
		WLCameraViewController* cameraController = segue.destinationViewController;
		cameraController.mode = WLCameraModeCandy;
		cameraController.delegate = self;
		[UIView beginAnimations:nil context:nil];
		self.firstContributorView.alpha = 0.0f;
		[UIView commitAnimations];
	}
}

- (IBAction)notNow:(UIButton *)sender {
	[UIView beginAnimations:nil context:nil];
	self.firstContributorView.alpha = 0.0f;
	[UIView commitAnimations];
}

- (IBAction)editWrap:(id)sender {
	if (wrapEditing){
		return;
	}
	wrapEditing = YES;
	WLCreateWrapViewController* controller = [self.storyboard editWrapViewController];
	controller.wrap = self.wrap;
	[controller presentInViewController:self transition:WLWrapTransitionFromRight];
}

#pragma mark - WLWrapCandiesCellDelegate

- (void)wrapCandiesCell:(WLWrapCandiesCell*)cell didSelectCandy:(WLCandy*)candy {
	if (candy.type == WLCandyTypeImage) {
		WLCandyViewController *controller = [self.storyboard candyViewController];
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
	__weak typeof(self)weakSelf = self;
	[[WLUploadingQueue instance] uploadImage:image wrap:self.wrap success:^(id object) {
		[[WLDataCache cache] setCandy:object];
		[[WLDataCache cache] setWrap:weakSelf.wrap];
	} failure:^(NSError *error) {
	}];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	self.firstContributorView.alpha = 0.0f;
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
