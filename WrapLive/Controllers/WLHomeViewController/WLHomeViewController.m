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
#import "StreamView.h"
#import "WLCandyViewController.h"
#import "UIColor+CustomColors.h"
#import "WLComment.h"
#import "WLImageCache.h"
#import "WLCandy.h"
#import "WLWrapCandyCell.h"
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

static NSUInteger WLHomeTopWrapCandiesLimit = 6;
static NSUInteger WLHomeTopWrapCandiesLimit_2 = 3;

@interface WLHomeViewController () <UITableViewDataSource, UITableViewDelegate, WLCameraViewControllerDelegate, StreamViewDelegate, WLWrapBroadcastReceiver>

@property (weak, nonatomic) IBOutlet StreamView *topWrapStreamView;
@property (weak, nonatomic) IBOutlet UIView *headerWrapView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *headerWrapNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerWrapAuthorsLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *noWrapsView;
@property (strong, nonatomic) NSArray* wraps;
@property (strong, nonatomic) WLWrap* topWrap;
@property (strong, nonatomic) NSArray* latestCandies;
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
	
	UILongPressGestureRecognizer* removeGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(removeTopWrap:)];
	[self.headerWrapNameLabel.superview addGestureRecognizer:removeGestureRecognizer];
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
	return self.topWrap ? [self cameraViewController] : nil;
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

- (NSArray*)allWraps {
	NSMutableArray* wraps = [NSMutableArray arrayWithObject:self.topWrap];
	[wraps addObjectsFromArray:_wraps];
	return [wraps copy];
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapChanged:(WLWrap *)wrap {
	if (self.topWrap) {
		self.wraps = [self allWraps];
	}
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapCreated:(WLWrap *)wrap {
	[self fetchWraps:YES];
	self.tableView.contentOffset = CGPointZero;
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapRemoved:(WLWrap *)wrap {
	if ([wrap isEqualToEntry:self.topWrap]) {
		self.wraps = _wraps;
		__weak typeof(self)weakSelf = self;
		[self.topWrap update:^(id object) {
			[WLDataCache cache].wraps = [weakSelf allWraps];
		} failure:^(NSError *error) {
		}];
	} else {
		for (WLWrap* _wrap in _wraps) {
			if ([_wrap isEqualToEntry:wrap]) {
				_wraps = [_wraps arrayByRemovingObject:_wrap];
			}
		}
		[self.tableView reloadData];
	}
	[WLDataCache cache].wraps = [self allWraps];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyRemoved:(WLCandy *)candy {
	[self updateTopWrap];
	[WLDataCache cache].wraps = [self allWraps];
}

- (void)fetchWraps:(BOOL)refresh {
	if (self.loading) {
		return;
	}
	self.loading = YES;
	__weak typeof(self)weakSelf = self;
	[WLDataManager wraps:refresh success:^(NSArray* wraps, BOOL cached, BOOL stop) {
		weakSelf.wraps = wraps;
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

- (void)setTopWrap:(WLWrap *)topWrap {
	_topWrap = topWrap;
	[self updateTopWrap];
}

- (void)setWraps:(NSArray *)wraps {
	wraps = [wraps sortedEntries];
	WLWrap* topWrap = [wraps firstObject];
	_wraps = [wraps arrayByRemovingObject:topWrap];
	self.tableView.hidden = (topWrap == nil);
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
	[[WLUploadingQueue instance] updateWrap:wrap];
	self.headerWrapNameLabel.text = wrap.name;
	self.headerWrapAuthorsLabel.text = wrap.contributorNames;
	[self.headerWrapAuthorsLabel sizeToFitHeightWithMaximumHeightToSuperviewBottom];
	self.latestCandies = [wrap candies:WLHomeTopWrapCandiesLimit];
	self.headerView.height = [self.latestCandies count] > WLHomeTopWrapCandiesLimit_2 ? 280 : 174;
	self.tableView.tableHeaderView = self.headerView;
	[self.topWrapStreamView reloadData];
}

- (void)appendWraps:(id)object {
	_wraps = [_wraps arrayByAddingObjectsFromArray:object];
	[self.tableView reloadData];
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

- (void)removeTopWrap:(UILongPressGestureRecognizer*)sender {
	if (sender.state == UIGestureRecognizerStateBegan && sender.view.userInteractionEnabled) {
		__weak typeof(self)weakSelf = self;
		WLWrap* wrap = weakSelf.topWrap;
		if ([wrap.contributor isCurrentUser]) {
			[UIActionSheet showWithTitle:nil cancel:@"Cancel" destructive:@"Delete" buttons:nil completion:^(NSUInteger index) {
				[UIActionSheet showWithTitle:@"Are you sure you want to delete this wrap?" cancel:@"No" destructive:@"Yes" buttons:nil completion:^(NSUInteger index) {
					sender.view.userInteractionEnabled = NO;
					[[WLAPIManager instance] removeWrap:wrap success:^(id object) {
						sender.view.userInteractionEnabled = YES;
					} failure:^(NSError *error) {
						[error show];
						sender.view.userInteractionEnabled = YES;
					}];
				}];
			}];
		}
	}
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.width, tableView.sectionHeaderHeight)];
	label.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.88];
	label.text = @"Your other wraps";
	label.textAlignment = NSTextAlignmentCenter;
	label.textColor = [UIColor WL_orangeColor];
	label.font = [UIFont lightFontOfSize:20];
	label.userInteractionEnabled = YES;
	return label;
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

#pragma mark - StreamViewDelegate

- (NSInteger)streamViewNumberOfColumns:(StreamView *)streamView {
	return 3;
}

- (NSInteger)streamView:(StreamView*)streamView numberOfItemsInSection:(NSInteger)section {
	return ([self.latestCandies count] > WLHomeTopWrapCandiesLimit_2) ? WLHomeTopWrapCandiesLimit : WLHomeTopWrapCandiesLimit_2;
}

- (UIView*)streamView:(StreamView*)streamView viewForItem:(StreamLayoutItem*)item {
	if (item.index.row < [self.latestCandies count]) {
		WLWrapCandyCell* candyView = [streamView reusableViewOfClass:[WLWrapCandyCell class]
															 forItem:item
														 loadingType:StreamViewReusableViewLoadingTypeNib];
		candyView.item = [self.latestCandies objectAtIndex:item.index.row];
		candyView.wrap = self.topWrap;
		return candyView;
	} else {
		UIImageView * placeholderView = [streamView reusableViewOfClass:[UIImageView class]
															forItem:item
														loadingType:StreamViewReusableViewLoadingTypeInit];
		placeholderView.image = [UIImage imageNamed:@"img_just_candy_small"];
		placeholderView.contentMode = UIViewContentModeCenter;
		placeholderView.alpha = 0.5;
		return placeholderView;
	}
}

- (CGFloat)streamView:(StreamView*)streamView ratioForItemAtIndex:(StreamIndex)index {
	return 1;
}

- (void)streamView:(StreamView *)streamView didSelectItem:(StreamLayoutItem *)item {
	if (item.index.row < [self.latestCandies count]) {
		WLCandy* candy = [self.latestCandies objectAtIndex:item.index.row];
		if (candy.uploadingItem == nil) {
			if (candy.type == WLCandyTypeImage) {
				WLWrapViewController* wrapController = [self.storyboard wrapViewController];
				wrapController.wrap = self.topWrap;
				WLCandyViewController* candyController = [self.storyboard candyViewController];
				[candyController setWrap:self.topWrap candy:candy];
				NSArray* controllers = @[self, wrapController, candyController];
				[self.navigationController setViewControllers:controllers animated:YES];
			} else if (candy.type == WLCandyTypeChatMessage) {
				WLWrapViewController* wrapController = [self.storyboard wrapViewController];
				wrapController.wrap = self.topWrap;
				WLChatViewController *chatController = [self.storyboard chatViewController];
				chatController.wrap = self.topWrap;
				NSArray* controllers = @[self, wrapController, chatController];
				[self.navigationController setViewControllers:controllers animated:YES];
			}
		}
	} else {
		[self presentViewController:[self cameraViewController] animated:YES completion:nil];
	}
}

@end
