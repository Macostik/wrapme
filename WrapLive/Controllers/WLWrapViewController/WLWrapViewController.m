//
//  WLWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapViewController.h"
#import "WLWrap.h"
#import "WLCandiesCell.h"
#import "WLImageFetcher.h"
#import "WLCandy.h"
#import "NSDate+Formatting.h"
#import "WLWrapDate.h"
#import "UIView+Shorthand.h"
#import "WLNavigation.h"
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
#import "WLUserChannelBroadcaster.h"
#import "WLToast.h"
#import "WLEntryState.h"
#import "WLStillPictureViewController.h"

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, WLCandiesCellDelegate, WLWrapBroadcastReceiver, WLUserChannelBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UITableView* tableView;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet UIView *firstContributorView;
@property (weak, nonatomic) IBOutlet UILabel *firstContributorWrapNameLabel;
@property (nonatomic) BOOL shouldLoadMoreDates;

@property (weak, nonatomic) WLRefresher *refresher;

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
	[[WLUserChannelBroadcaster broadcaster] addReceiver:self];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	wrapEditing = NO;
	[self.wrap setUpdated:NO];
}

- (void)setWrapData {
	self.coverView.url = self.wrap.picture.small;
	self.nameLabel.text = self.wrap.name;
	self.contributorsLabel.text = self.wrap.contributorNames;
	[self.contributorsLabel sizeToFitHeightWithMaximumHeightToSuperviewBottom];
}

#pragma mark - WLUserChannelBroadcastReceiver

- (void)broadcaster:(WLUserChannelBroadcaster *)broadcaster didResignContributor:(WLWrap *)wrap {
	if ([self.wrap isEqualToEntry:wrap]) {
		[WLToast showWithMessage:@"This wrap is no longer avaliable."];
	}
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
		if (!date.candies.nonempty) {
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
	[[WLUploadingQueue instance] checkStatus];
	[WLDataManager wrap:self.wrap success:^(WLWrap* wrap, BOOL cached, BOOL stop) {
		[[WLUploadingQueue instance] updateWrap:weakSelf.wrap];
		if (!cached) {
			weakSelf.firstContributorView.alpha = wrap.dates.nonempty ? 0.0f : 1.0f;
			if (weakSelf.firstContributorView.alpha == 1.0f) {
				weakSelf.firstContributorWrapNameLabel.text = wrap.name;
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

- (void)appendDates {
	if (loading || !self.wrap.dates.nonempty || [self.wrap.dates count] % WLAPIGeneralPageSize > 0) {
		return;
	}
	loading = YES;
	__weak typeof(self)weakSelf = self;
	NSInteger page = floorf([self.wrap.dates count] / WLAPIGeneralPageSize) + 1;
	[[WLAPIManager instance] wrap:[self.wrap copy] page:page success:^(WLWrap* wrap) {
		weakSelf.wrap.dates = (id)[weakSelf.wrap.dates entriesByAddingEntries:wrap.dates];
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

- (id)cameraViewController {
	return [WLStillPictureViewController instantiate:^(WLStillPictureViewController* controller) {
		controller.delegate = self;
		controller.mode = WLCameraModeCandy;
	}];
}

- (IBAction)typeMessage:(UIButton *)sender {
	WLChatViewController * chatController = [WLChatViewController instantiate];
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
		WLStillPictureViewController* controller = segue.destinationViewController;
		controller.mode = WLCameraModeCandy;
		controller.delegate = self;
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
	WLCreateWrapViewController* controller = [WLCreateWrapViewController instantiate];
	controller.wrap = self.wrap;
	[controller presentInViewController:self transition:WLWrapTransitionFromRight];
}

#pragma mark - WLCandiesCellDelegate

- (void)candiesCell:(WLCandiesCell*)cell didSelectCandy:(WLCandy*)candy {
	if (candy.type == WLCandyTypeImage) {
		WLCandyViewController *controller = [WLCandyViewController instantiate];
		[controller setWrap:self.wrap candy:candy];
		[self.navigationController pushViewController:controller animated:YES];
	} else if (candy.type == WLCandyTypeChatMessage) {
		WLChatViewController * chatController = [WLChatViewController instantiate];
		chatController.wrap = self.wrap;
		[self.navigationController pushViewController:chatController animated:YES];
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.wrap.dates count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLCandiesCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLCandiesCell reuseIdentifier]];
	
	WLWrapDate* date = [self.wrap.dates objectAtIndex:indexPath.row];
	
	cell.item = date;
	cell.wrap = self.wrap;
	cell.delegate = self;
	
	if (date == [self.wrap.dates lastObject] && self.shouldLoadMoreDates) {
		[self appendDates];
	}
	
    return cell;
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithImage:(UIImage *)image {
	self.firstContributorView.alpha = 0.0f;
	__weak typeof(self)weakSelf = self;
	[[WLUploadingQueue instance] uploadImage:image wrap:self.wrap success:^(id object) {
		[[WLDataCache cache] setCandy:object];
		[[WLDataCache cache] setWrap:weakSelf.wrap];
	} failure:^(NSError *error) {
	}];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
	self.firstContributorView.alpha = 0.0f;
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
