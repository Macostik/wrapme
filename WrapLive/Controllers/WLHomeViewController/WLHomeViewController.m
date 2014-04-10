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
#import "WLAPIManager.h"
#import "WLWrapViewController.h"
#import "UIStoryboard+Additions.h"
#import "UIView+Shorthand.h"
#import "WLCameraViewController.h"
#import "NSArray+Additions.h"
#import "NSDate+Formatting.h"
#import "StreamView.h"
#import "WLWrapDataViewController.h"
#import "UIColor+CustomColors.h"
#import "WLComposeBar.h"
#import "WLComposeContainer.h"
#import "WLComment.h"
#import "UIImage+WLStoring.h"
#import "WLCandy.h"
#import "WLWrapCandyCell.h"
#import "UIFont+CustomFonts.h"
#import "WLProgressView.h"
#import "WLRefresher.h"
#import "WLChatViewController.h"
#import "WLLoadingView.h"
#import "UIViewController+Additions.h"

@interface WLHomeViewController () <UITableViewDataSource, UITableViewDelegate, WLCameraViewControllerDelegate, StreamViewDelegate, WLComposeBarDelegate>

@property (weak, nonatomic) IBOutlet StreamView *topWrapStreamView;
@property (weak, nonatomic) IBOutlet UIView *headerWrapView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *headerWrapNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerWrapCreatedAtLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerWrapAuthorsLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *noWrapsView;
@property (weak, nonatomic) IBOutlet WLComposeContainer *composeContainer;
@property (strong, nonatomic) NSArray* wraps;
@property (strong, nonatomic) WLWrap* topWrap;
@property (strong, nonatomic) NSArray* latestCandies;
@property (nonatomic) BOOL loading;
@property (weak, nonatomic) WLRefresher *refresher;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIButton *createWrapButton;

@end

@implementation WLHomeViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
													name:WLWrapChangesNotification
												  object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.navigationBar.transform = CGAffineTransformMakeTranslation(0, -self.navigationBar.height);
	self.createWrapButton.transform = CGAffineTransformMakeTranslation(0, self.createWrapButton.height);
	self.composeContainer.hidden = YES;
	self.noWrapsView.hidden = YES;
	[self setupRefresh];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeNotificationReceived:)
												 name:WLWrapChangesNotification
											   object:nil];
	self.tableView.tableFooterView = [WLLoadingView instance];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.composeContainer.hidden) {
		self.loading = NO;
		[self fetchWraps:1];
	}
}

- (UIViewController *)shakePresentedViewController {
	return self.topWrap ? [self cameraViewController] : nil;
}

- (WLCameraViewController*)cameraViewController {
	WLCameraViewController* cameraController = [self.storyboard cameraViewController];
	cameraController.delegate = self;
	cameraController.mode = WLCameraModeFullSize;
	cameraController.backfacingByDefault = YES;
	return cameraController;
}

- (void)setupRefresh {
	__weak typeof(self)weakSelf = self;
	self.refresher = [WLRefresher refresherWithScrollView:self.tableView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf fetchWraps:1];
	}];
	self.refresher.colorScheme = WLRefresherColorSchemeOrange;
	self.refresher.contentMode = UIViewContentModeLeft;
}


- (void)changeNotificationReceived:(NSNotification*)notification {
	BOOL isNeedRequest = [[notification.userInfo objectForKey:@"isNeedRequest"] boolValue];
	if (isNeedRequest) {
		[self fetchWraps:1];
	}
	else {
		[self.tableView reloadData];
		[self.topWrapStreamView reloadData];
	}
}

- (void)fetchWraps:(NSInteger)page {
	if (self.loading) {
		return;
	}
	self.loading = YES;
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] wrapsWithPage:page success:^(NSArray * object) {
		if (page == 1) {
			weakSelf.wraps = object;
		} else {
			[weakSelf appendWraps:object];
		}
		[weakSelf validateFooterWithObjectsCount:object.count];
		weakSelf.loading = NO;
		[weakSelf.refresher endRefreshing];
		[weakSelf finishLoadingAnimation];
	} failure:^(NSError *error) {
		weakSelf.loading = NO;
		[weakSelf.refresher endRefreshing];
		[error show];
		[weakSelf finishLoadingAnimation];
	}];
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

- (void)validateFooterWithObjectsCount:(int)count {
	if (count < WLAPIGeneralPageSize) {
		self.tableView.tableFooterView = nil;
	} else if (self.tableView.tableFooterView == nil) {
		self.tableView.tableFooterView = [WLLoadingView instance];
	}
}

- (void)setTopWrap:(WLWrap *)topWrap {
	_topWrap = topWrap;
	[self updateTopWrap];
}

- (void)setWraps:(NSArray *)wraps {
	wraps = [wraps sortedEntries];
	WLWrap* topWrap = [wraps firstObject];
	_wraps = [wraps arrayByRemovingObject:topWrap];
	self.composeContainer.hidden = (topWrap == nil);
	self.noWrapsView.hidden = (topWrap != nil);
	self.topWrap = topWrap;
	[self.tableView reloadData];
	
	if (topWrap && !CGAffineTransformIsIdentity(self.navigationBar.transform)) {
		__weak typeof(self)weakSelf = self;
		[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
			weakSelf.navigationBar.transform = CGAffineTransformIdentity;
		} completion:^(BOOL finished) {
		}];
	}
}

- (void)updateTopWrap {
	WLWrap* wrap = self.topWrap;
	self.headerWrapNameLabel.text = wrap.name;
	self.headerWrapCreatedAtLabel.text = [wrap.createdAt stringWithFormat:@"MMMM dd, yyyy"];
	__weak typeof(self)weakSelf = self;
	[wrap contributorNames:^(NSString *names) {
		weakSelf.headerWrapAuthorsLabel.text = names;
	}];
	self.latestCandies = [wrap latestCandies:5];
	self.headerView.height = [self.latestCandies count] > 2 ? 212 : 106;
	self.tableView.tableHeaderView = self.headerView;
	[self.topWrapStreamView reloadData];
}

- (void)appendWraps: (id)object {
	_wraps = [_wraps arrayByAddingObjectsFromArray:object];
	[self.tableView reloadData];
}

- (void)sendMessageWithText:(NSString*)text {
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] addCandy:[WLCandy chatMessageWithText:text]
							   toWrap:self.topWrap
							  success:^(id object) {
		[weakSelf updateTopWrap];
	} failure:^(NSError *error) {
		[error show];
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
		cameraController.mode = WLCameraModeFullSize;
		cameraController.backfacingByDefault = YES;
	}
}

#pragma mark - Actions

- (IBAction)typeMessage:(UIButton *)sender {
//	WLChatViewController * chatController = [self.storyboard chatViewController];
//	chatController.wrap = self.topWrap;
//	chatController.shouldShowKeyboard = YES;
//	[self.navigationController pushViewController:chatController animated:YES];
	[self.composeContainer setEditing:!self.composeContainer.editing animated:YES];
}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[self.composeContainer setEditing:NO animated:YES];
	[self sendMessageWithText:text];
}

- (void)composeBarDidReturn:(WLComposeBar *)composeBar {
	[self.composeContainer setEditing:NO animated:YES];
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.wraps count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString* wrapCellIdentifier = @"WLWrapCell";
	WLWrapCell* cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier
													   forIndexPath:indexPath];
	cell.item = [self.wraps objectAtIndex:(indexPath.row)];
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return [tableView dequeueReusableCellWithIdentifier:@"LabelCell"];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!self.loading && self.tableView.tableFooterView != nil && (indexPath.row == [self.wraps count] - 1)) {
		NSInteger page = ((self.wraps.count + 1)/WLAPIGeneralPageSize + 1);
		[self fetchWraps:page];
	}
}

#pragma mark - <WLCameraViewControllerDelegate>

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	__weak typeof(self)weakSelf = self;
	
	[WLProgressView showWithMessage:@"Uploading image..." image:image operation:nil];
	
	[image storeAsImage:^(NSString *path) {
		
		id operation = [[WLAPIManager instance] addCandy:[WLCandy imageWithFileAtPath:path]
												  toWrap:weakSelf.topWrap
												 success:^(id object) {
			[WLProgressView dismiss];
			[weakSelf updateTopWrap];
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

#pragma mark - StreamViewDelegate

- (NSInteger)streamViewNumberOfColumns:(StreamView *)streamView {
	return 3;
}

- (NSInteger)streamView:(StreamView*)streamView numberOfItemsInSection:(NSInteger)section {
	return ([self.latestCandies count] > 2) ? 5 : 2;
}

- (UIView*)streamView:(StreamView*)streamView viewForItem:(StreamLayoutItem*)item {
	if (item.index.row < [self.latestCandies count]) {
		WLWrapCandyCell* candyView = [streamView reusableViewOfClass:[WLWrapCandyCell class]
															 forItem:item
														 loadingType:StreamViewReusableViewLoadingTypeNib];
		candyView.item = [self.latestCandies objectAtIndex:item.index.row];
		return candyView;
	} else {
		UIImageView * placeholderView = [streamView reusableViewOfClass:[UIImageView class]
															forItem:item
														loadingType:StreamViewReusableViewLoadingTypeInit];
		placeholderView.image = [UIImage imageNamed:@"ic_candy"];
		return placeholderView;
	}
}

- (CGFloat)streamView:(StreamView*)streamView ratioForItemAtIndex:(StreamIndex)index {
	return 1;
}

- (CGFloat)streamView:(StreamView *)streamView initialRangeForColumn:(NSInteger)column {
	return column == 1 ? 106 : 0;
}

- (CGFloat)streamViewSpacing:(StreamView *)streamView {
	return 1;
}

- (void)streamView:(StreamView *)streamView didSelectItem:(StreamLayoutItem *)item {
	if (item.index.row < [self.latestCandies count]) {
		WLCandy* candy = [self.latestCandies objectAtIndex:item.index.row];
		if (candy.type == WLCandyTypeImage) {
			WLWrapDataViewController* controller = [self.storyboard wrapDataViewController];
			controller.candy = candy;
			controller.wrap = self.topWrap;
			[self pushViewController:controller animated:YES];
		} else if (candy.type == WLCandyTypeChatMessage) {
			WLChatViewController * chatController = [self.storyboard chatViewController];
			chatController.wrap = self.topWrap;
			[self pushViewController:chatController animated:YES];
		}
	} else {
		[self presentViewController:[self cameraViewController] animated:YES completion:nil];
	}
}

@end
