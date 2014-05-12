//
//  WLHomeViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLHomeViewController.h"
#import "WLWrapCell.h"
#import "WLWrap.h"
#import "WLCandy.h"
#import "UIImageView+ImageLoading.h"
#import "WLWrapViewController.h"
#import "UIStoryboard+Additions.h"
#import "UIView+Shorthand.h"
#import "WLCameraViewController.h"
#import "NSArray+Additions.h"
#import "NSDate+Formatting.h"
#import "WLCandyViewController.h"
#import "UIColor+CustomColors.h"
#import "WLComment.h"
#import "WLImageCache.h"
#import "WLCandy.h"
#import "UIFont+CustomFonts.h"
#import "WLRefresher.h"
#import "WLChatViewController.h"
#import "WLLoadingView.h"
#import "UIViewController+Additions.h"
#import "WLWrapBroadcaster.h"
#import "WLUploadingQueue.h"
#import "UILabel+Additions.h"
#import "WLCreateWrapViewController.h"
#import "WLUser.h"
#import "WLDataManager.h"
#import "WLWrapDate.h"
#import "WLDataCache.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"

@interface WLHomeViewController () <UITableViewDataSource, UITableViewDelegate, WLCameraViewControllerDelegate, WLWrapBroadcastReceiver, WLWrapCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *noWrapsView;
@property (strong, nonatomic) NSArray* wraps;
@property (strong, nonatomic) NSArray* candies;
@property (nonatomic, readonly) WLWrap* topWrap;
@property (nonatomic) BOOL loading;
@property (weak, nonatomic) WLRefresher *refresher;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIButton *createWrapButton;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@property (nonatomic) BOOL shouldAppendMoreWraps;

@end

@implementation WLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.navigationBar.transform = CGAffineTransformMakeTranslation(0, -self.navigationBar.height);
	self.createWrapButton.transform = CGAffineTransformMakeTranslation(0, self.createWrapButton.height);
	self.tableView.hidden = YES;
	self.noWrapsView.hidden = YES;
	
	[self setupRefresh];
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
	self.tableView.tableFooterView = [WLLoadingView instance];
	
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.avatarImageView.layer.cornerRadius = self.avatarImageView.height/2;
	self.avatarImageView.layer.borderWidth = 1;
	self.avatarImageView.layer.borderColor = [UIColor whiteColor].CGColor;
	self.avatarImageView.imageUrl = [WLUser currentUser].picture.small;
	if (self.tableView.hidden) {
		self.loading = NO;
		[self fetchWraps:YES];
	}
}

- (UIViewController *)shakePresentedViewController {
	return [self.wraps count] > 0 ? [self cameraViewController] : nil;
}

- (WLCameraViewController*)cameraViewController {
	WLCameraViewController* cameraController = [self.storyboard cameraViewController];
	cameraController.delegate = self;
	cameraController.mode = WLCameraModeCandy;
	return cameraController;
}

- (void)setupRefresh {
	__weak typeof(self)weakSelf = self;
	self.refresher = [WLRefresher refresherWithScrollView:self.tableView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf fetchWraps:YES];
	}];
	self.refresher.colorScheme = WLRefresherColorSchemeWhite;
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapChanged:(WLWrap *)wrap {
	[self updateWraps];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapCreated:(WLWrap *)wrap {
	NSMutableArray* wraps = [self.wraps mutableCopy];
	[wraps insertObject:wrap atIndex:0];
	self.wraps = [wraps copy];
	[self fetchWraps:YES];
	self.tableView.contentOffset = CGPointZero;
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapRemoved:(WLWrap *)wrap {
	self.wraps = [self.wraps entriesByRemovingEntry:wrap];
	__weak typeof(self)weakSelf = self;
	[self.topWrap fetch:^(WLWrap* wrap) {
		[WLDataCache cache].wraps = weakSelf.wraps;
	} failure:^(NSError *error) {
	}];
	[WLDataCache cache].wraps = self.wraps;
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyRemoved:(WLCandy *)candy {
	[self updateWraps];
	[WLDataCache cache].wraps = self.wraps;
}

- (void)fetchWraps:(BOOL)refresh {
	if (self.loading) {
		return;
	}
	self.loading = YES;
	__weak typeof(self)weakSelf = self;
	[WLDataManager wraps:refresh success:^(NSArray* wraps, BOOL cached, BOOL stop) {
		weakSelf.wraps = wraps;
		[weakSelf showLatestWrap];
		weakSelf.shouldAppendMoreWraps = !stop;
		if (!cached) {
			[weakSelf.refresher endRefreshing];
			weakSelf.loading = NO;
		}
		[weakSelf finishLoadingAnimation];
	} failure:^(NSError *error) {
		weakSelf.loading = NO;
		weakSelf.shouldAppendMoreWraps = NO;
		[weakSelf.refresher endRefreshing];
		if (weakSelf.isOnTopOfNagvigation) {
			[error showIgnoringNetworkError];
		}
		[weakSelf finishLoadingAnimation];
	}];
}

- (void)showLatestWrap {
	WLUser * user = [WLUser currentUser];
	if (!user.firstWrapShown && [user signInCount] == 1 && self.wraps.count > 0) {
		[user setFirstWrapShown:YES];
		WLWrapViewController* wrapController = [self.storyboard wrapViewController];
		wrapController.wrap = [self.wraps firstObject];
		[self.navigationController pushViewController:wrapController animated:NO];
	}
}

- (void)finishLoadingAnimation {
	if (!CGAffineTransformIsIdentity(self.createWrapButton.transform)) {
		__weak typeof(self)weakSelf = self;
		[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
			weakSelf.loadingView.alpha = 0.0f;
			weakSelf.createWrapButton.transform = CGAffineTransformIdentity;
		} completion:^(BOOL finished) {
			[weakSelf.loadingView removeFromSuperview];
		}];
	}
}

- (void)setShouldAppendMoreWraps:(BOOL)shouldAppendMoreWraps {
	_shouldAppendMoreWraps = shouldAppendMoreWraps;
	if (!_shouldAppendMoreWraps) {
		self.tableView.tableFooterView = nil;
	} else if (self.tableView.tableFooterView == nil) {
		self.tableView.tableFooterView = [WLLoadingView instance];
	}
}

- (void)setWraps:(NSArray *)wraps {
	_wraps = [wraps entriesSortedByUpdatingDate];
	[self updateWraps];
}

- (WLWrap *)topWrap {
	return [self.wraps firstObject];
}

- (void)updateWraps {
	
	BOOL hasWraps = [_wraps count] > 0;
	
	if (hasWraps) {
		WLWrap* wrap = self.topWrap;
		[[WLUploadingQueue instance] updateWrap:wrap];
		self.candies = [wrap candies:WLHomeTopWrapCandiesLimit];
	}
	
	self.tableView.hidden = !hasWraps;
	self.noWrapsView.hidden = hasWraps;
	[self.tableView reloadData];
	
	if (hasWraps && !CGAffineTransformIsIdentity(self.navigationBar.transform)) {
		__weak typeof(self)weakSelf = self;
		[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
			weakSelf.navigationBar.transform = CGAffineTransformIdentity;
		} completion:^(BOOL finished) {
		}];
	}
}

- (void)sendMessageWithText:(NSString*)text {
	[[WLUploadingQueue instance] uploadMessage:text wrap:self.topWrap success:^(id object) {
	} failure:^(NSError *error) {
	}];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isWrapSegue]) {
		WLWrap* wrap = [self.wraps objectAtIndex:[self.tableView indexPathForSelectedRow].row];
		[(WLWrapViewController* )segue.destinationViewController setWrap:wrap];
	} else if ([segue isTopWrapSegue]) {
		[(WLWrapViewController* )segue.destinationViewController setWrap:self.topWrap];
	} else if ([segue isCameraSegue]) {
		WLCameraViewController* cameraController = segue.destinationViewController;
		cameraController.delegate = self;
		cameraController.mode = WLCameraModeCandy;
	}
}

#pragma mark - Actions

- (IBAction)typeMessage:(UIButton *)sender {
	WLChatViewController * chatController = [self.storyboard chatViewController];
	chatController.wrap = self.topWrap;
	chatController.shouldShowKeyboard = YES;
	[self.navigationController pushViewController:chatController animated:YES];
}

- (IBAction)createNewWrap:(id)sender {
	WLCreateWrapViewController* controller = [self.storyboard editWrapViewController];
	[controller presentInViewController:self transition:WLWrapTransitionFromBottom];
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.wraps count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLWrap* wrap = [self.wraps objectAtIndex:(indexPath.row)];
	WLWrapCell* cell = nil;
	if (indexPath.row == 0) {
		static NSString* topWrapCellIdentifier = @"WLTopWrapCell";
		cell = [tableView dequeueReusableCellWithIdentifier:topWrapCellIdentifier forIndexPath:indexPath];
		cell.candies = self.candies;
	} else {
		static NSString* wrapCellIdentifier = @"WLWrapCell";
		cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier forIndexPath:indexPath];
	}
	cell.item = wrap;
	cell.delegate = self;
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == 0) {
		return [self.candies count] > WLHomeTopWrapCandiesLimit_2 ? 324 : 218;
	}
	return 50;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!self.loading && self.tableView.tableFooterView != nil && (indexPath.row == [self.wraps count] - 1)) {
		[self fetchWraps:NO];
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if (self.refresher.refreshing) {
		[self.refresher endRefreshingAfterDelay:0.0f];
	}
}

#pragma mark - <WLCameraViewControllerDelegate>

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {	
	[[WLUploadingQueue instance] uploadImage:image wrap:self.topWrap success:^(id object) {
	} failure:^(NSError *error) {
	}];

	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WLWrapCellDelegate

- (void)wrapCell:(WLWrapCell *)cell didSelectCandy:(WLCandy *)candy {
	WLWrapViewController* wrapController = [self.storyboard wrapViewController];
	wrapController.wrap = cell.item;
	UIViewController* controller = nil;
	if (candy.type == WLCandyTypeImage) {
		WLCandyViewController* candyController = [self.storyboard candyViewController];
		[candyController setWrap:cell.item candy:candy];
		controller = candyController;
	} else if (candy.type == WLCandyTypeChatMessage) {
		WLChatViewController *chatController = [self.storyboard chatViewController];
		chatController.wrap = cell.item;
		controller = chatController;
	}
	NSArray* controllers = @[self, wrapController, controller];
	[self.navigationController setViewControllers:controllers animated:YES];
}

- (void)wrapCellDidSelectCandyPlaceholder:(WLWrapCell *)cell {
	[self presentViewController:[self cameraViewController] animated:YES completion:nil];
}

@end
