//
//  WLHomeViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLHomeViewController.h"
#import "WLWrapCell.h"
#import "WLEntryManager.h"
#import "WLImageFetcher.h"
#import "WLWrapViewController.h"
#import "WLNavigation.h"
#import "UIView+Shorthand.h"
#import "WLCameraViewController.h"
#import "NSArray+Additions.h"
#import "NSDate+Formatting.h"
#import "WLCandyViewController.h"
#import "UIColor+CustomColors.h"
#import "WLComment.h"
#import "WLImageCache.h"
#import "UIFont+CustomFonts.h"
#import "WLRefresher.h"
#import "WLChatViewController.h"
#import "WLLoadingView.h"
#import "UIViewController+Additions.h"
#import "WLWrapBroadcaster.h"
#import "UILabel+Additions.h"
#import "WLCreateWrapViewController.h"
#import "WLDataManager.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "WLToast.h"
#import "WLStillPictureViewController.h"
#import "WLSupportFunctions.h"
#import "NSString+Additions.h"
#import "WLQuickChatView.h"
#import "WLNotificationBroadcaster.h"
#import "WLNotification.h"
#import "UIView+AnimationHelper.h"
#import "AsynchronousOperation.h"

@interface WLHomeViewController () <UITableViewDataSource, UITableViewDelegate, WLStillPictureViewControllerDelegate, WLWrapBroadcastReceiver, WLWrapCellDelegate, WLNotificationReceiver, WLQuickChatViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *noWrapsView;
@property (strong, nonatomic) NSOrderedSet* wraps;
@property (strong, nonatomic) NSOrderedSet* candies;
@property (nonatomic, strong) WLWrap* topWrap;
@property (nonatomic) BOOL loading;
@property (weak, nonatomic) WLRefresher *refresher;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (weak, nonatomic) WLLoadingView *splash;
@property (weak, nonatomic) IBOutlet UIButton *createWrapButton;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet WLQuickChatView *quickChatView;
@property (strong, nonatomic) WLLoadingView *loadingView;
@property (strong, nonatomic) NSOperationQueue *loadingQueue;

@end

@implementation WLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.splash = [[WLLoadingView splash] showInView:self.view];
    
    [self setNavigationBarHidden:YES animated:NO];
	self.createWrapButton.transform = CGAffineTransformMakeTranslation(0, self.createWrapButton.height);
	self.tableView.hidden = YES;
	self.noWrapsView.hidden = YES;
	[self setupRefresh];
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
	[[WLNotificationBroadcaster broadcaster] addReceiver:self];
	self.loadingView = [WLLoadingView instance];
}

- (void)setLoadingView:(WLLoadingView *)loadingView {
    self.tableView.tableFooterView = loadingView;
}

- (WLLoadingView *)loadingView {
    return (WLLoadingView*)self.tableView.tableFooterView;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    self.avatarImageView.circled = YES;
	self.avatarImageView.layer.borderWidth = 1;
	self.avatarImageView.layer.borderColor = [UIColor whiteColor].CGColor;
	self.avatarImageView.url = [WLUser currentUser].picture.small;
    NSOrderedSet* wraps = [[WLUser currentUser] sortedWraps];
	if (self.tableView.hidden) {
		self.loading = NO;
		[self fetchWraps:YES];
        if (wraps.nonempty) {
            self.wraps = wraps;
        }
	} else {
        self.wraps = wraps;
    }
}

- (CGFloat)toastAppearanceHeight:(WLToast *)toast {
	return 84.0f;
}

- (UIViewController *)shakePresentedViewController {
	return self.wraps.nonempty ? [self cameraViewController] : nil;
}

- (id)cameraViewController {
	__weak typeof(self)weakSelf = self;
	return [WLStillPictureViewController instantiate:^(WLStillPictureViewController* controller) {
		controller.wrap = weakSelf.topWrap;
		controller.delegate = self;
		controller.mode = WLCameraModeCandy;
	}];
}

- (void)setupRefresh {
	__weak typeof(self)weakSelf = self;
	self.refresher = [WLRefresher refresherWithScrollView:self.tableView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf fetchWraps:YES];
	}];
	self.refresher.colorScheme = WLRefresherColorSchemeWhite;
}

- (void)fetchWraps:(BOOL)refresh {
	if (self.loading) {
		return;
	}
	self.loading = YES;
    self.loadingView.error = NO;
	__weak typeof(self)weakSelf = self;
	[WLDataManager wraps:refresh success:^(NSOrderedSet* wraps, BOOL stop) {
		weakSelf.wraps = wraps;
		[weakSelf showLatestWrap];
        if (stop) {
            weakSelf.loadingView = nil;
        }
		[weakSelf.refresher endRefreshing];
        weakSelf.loading = NO;
	} failure:^(NSError *error) {
        weakSelf.loadingView.error = YES;
		weakSelf.loading = NO;
		[weakSelf.refresher endRefreshing];
		if (weakSelf.isOnTopOfNagvigation) {
			[error showIgnoringNetworkError];
		}
		[weakSelf finishLoadingAnimation];
	}];
}

- (void)showLatestWrap {
    WLUser * user = [WLUser currentUser];
    static BOOL firstWrapShown = NO;
	if (!firstWrapShown && user.signInCount.integerValue == 1 && self.wraps.nonempty) {
		WLWrapViewController* wrapController = [WLWrapViewController instantiate];
		wrapController.wrap = [self.wraps firstObject];
		[self.navigationController pushViewController:wrapController animated:NO];
	}
    firstWrapShown = YES;
}

- (void)finishLoadingAnimation {
	if (!CGAffineTransformIsIdentity(self.createWrapButton.transform)) {
		__weak typeof(self)weakSelf = self;
		[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
			weakSelf.splash.alpha = 0.0f;
			weakSelf.createWrapButton.transform = CGAffineTransformIdentity;
		} completion:^(BOOL finished) {
			[weakSelf.splash hide];
		}];
	}
}

- (void)setWraps:(NSOrderedSet *)wraps {
	_wraps = wraps;
	[self updateWraps];
}

- (void)updateWraps {
	
	BOOL hasWraps = _wraps.nonempty;
	
    self.quickChatView.hidden = !hasWraps;
    
    self.topWrap = [self.wraps firstObject];
	
	self.tableView.hidden = !hasWraps;
	self.noWrapsView.hidden = hasWraps;
	[self.tableView reloadData];
	
	[self setNavigationBarHidden:!hasWraps animated:YES];
    
    [self finishLoadingAnimation];
}

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated {
    __weak typeof(self)weakSelf = self;
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, hidden ? -weakSelf.navigationBar.height : 0);
    if (!CGAffineTransformEqualToTransform(self.navigationBar.transform, transform)) {
        [UIView performAnimated:animated animation:^{
            weakSelf.navigationBar.transform = transform;
        }];
    }
}

- (void)setTopWrap:(WLWrap *)topWrap {
    if (_topWrap != topWrap) {
        _topWrap = topWrap;
        if (_topWrap) {
            [self fetchTopWrapIfNeeded:_topWrap];
        }
    }
    if (_topWrap) {
        self.candies = [_topWrap recentCandies:WLHomeTopWrapCandiesLimit];
        self.quickChatView.wrap = _topWrap;
    }
}

- (NSOperationQueue *)loadingQueue {
    if (!_loadingQueue) {
        _loadingQueue = [[NSOperationQueue alloc] init];
        _loadingQueue.maxConcurrentOperationCount = 1;
    }
    return _loadingQueue;
}

- (void)fetchTopWrapIfNeeded:(WLWrap*)wrap {
    if ([self.candies count] < WLHomeTopWrapCandiesLimit) {
        [self.loadingQueue addAsynchronousOperationWithBlock:^(AsynchronousOperation *operation) {
            run_in_main_queue(^{
                [wrap fetch:^(WLWrap* wrap) {
                    [operation finish];
                } failure:^(NSError *error) {
                    [operation finish];
                }];
            });
        }];
    }
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapChanged:(WLWrap *)wrap {
	self.wraps = [[WLUser currentUser] sortedWraps];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapCreated:(WLWrap *)wrap {
	self.wraps = [[WLUser currentUser] sortedWraps];
	self.tableView.contentOffset = CGPointZero;
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapRemoved:(WLWrap *)wrap {
	self.wraps = [[WLUser currentUser] sortedWraps];
}

#pragma mark - WLNotificationReceiver

- (void)handleRemoteNotification:(WLNotification*)notification {
	
    if ([notification deletion]) {
        return;
    }
    
    void (^showNotificationBlock)(void) = ^{
        WLWrap* wrap = notification.wrap;
		if (notification.type == WLNotificationContributorAddition) {
			[self.navigationController pushViewController:[WLWrapViewController instantiate:^(WLWrapViewController *controller) {
				controller.wrap = wrap;
			}] animated:YES];
		} else if (notification.type == WLNotificationImageCandyAddition || notification.type == WLNotificationChatCandyAddition || notification.type == WLNotificationCandyCommentAddition) {
            WLCandy* candy = notification.candy;
            [wrap addCandy:candy];
			[self presentCandy:candy fromWrap:wrap];
		}
	};
    
	UIViewController* presentedViewController = self.navigationController.presentedViewController;
	if (presentedViewController) {
		__weak typeof(self)weakSelf = self;
		[UIAlertView showWithTitle:@"View notification"
						   message:@"Incompleted data can be lost. Do you want to continue?"
							action:@"Continue"
							cancel:@"Cancel"
						completion:^{
			[weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
			showNotificationBlock();
		}];
	} else {
		showNotificationBlock();
	}
}

- (void)broadcaster:(WLNotificationBroadcaster *)broadcaster didReceiveRemoteNotification:(WLNotification *)notification {
	[self handleRemoteNotification:notification];
	broadcaster.pendingRemoteNotification = nil;
}

#pragma mark - Actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isCameraSegue]) {
		WLStillPictureViewController* controller = segue.destinationViewController;
		controller.wrap = self.topWrap;
		controller.delegate = self;
		controller.mode = WLCameraModeCandy;
	}
}

- (IBAction)typeMessage:(UIButton *)sender {
	WLChatViewController * chatController = [WLChatViewController instantiate];
	chatController.wrap = self.topWrap;
	chatController.shouldShowKeyboard = YES;
	[self.navigationController pushViewController:chatController animated:YES];
}

- (IBAction)createNewWrap:(id)sender {
	WLCreateWrapViewController* controller = [WLCreateWrapViewController instantiate];
	[controller presentInViewController:self transition:WLWrapTransitionFromBottom];
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.wraps count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLWrap* wrap = [self.wraps tryObjectAtIndex:indexPath.row];
	WLWrapCell* cell = nil;
	if (indexPath.row == 0) {
		static NSString* topWrapCellIdentifier = @"WLTopWrapCell";
		cell = [tableView dequeueReusableCellWithIdentifier:topWrapCellIdentifier forIndexPath:indexPath];
		cell.item = wrap;
		cell.candies = self.candies;
	} else {
		static NSString* wrapCellIdentifier = @"WLWrapCell";
		cell = [tableView dequeueReusableCellWithIdentifier:wrapCellIdentifier forIndexPath:indexPath];
		cell.item = wrap;
	}
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
	if (!self.loading && self.loadingView != nil && (indexPath.row == [self.wraps count] - 1)) {
		[self fetchWraps:NO];
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if (self.refresher.refreshing) {
		[self.refresher endRefreshingAfterDelay:0.0f];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.quickChatView onEndDragging];
    if (!decelerate) {
        [self.quickChatView onEndScrolling];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.quickChatView onEndScrolling];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.quickChatView onScroll];
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithImage:(UIImage *)image {
	WLWrap* wrap = controller.wrap ? : self.topWrap;
	[wrap uploadImage:image success:^(WLCandy *candy) {
    } failure:^(NSError *error) {
    }];

	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WLWrapCellDelegate

- (void)presentCandy:(WLCandy*)candy fromWrap:(WLWrap*)wrap {
	WLWrapViewController* wrapController = [WLWrapViewController instantiate];
	wrapController.wrap = wrap;
	UIViewController* controller = nil;
	if ([candy isImage]) {
		controller = [WLCandyViewController instantiate:^(WLCandyViewController *controller) {
            controller.candy = candy;
		}];
	} else if ([candy isMessage]) {
		controller = [WLChatViewController instantiate:^(WLChatViewController *controller) {
			controller.wrap = wrap;
		}];
	}
	if (controller) {
		NSArray* controllers = @[self, wrapController, controller];
		[self.navigationController setViewControllers:controllers animated:YES];
	}
}

- (void)wrapCell:(WLWrapCell *)cell didSelectCandy:(WLCandy *)candy {
	[self presentCandy:candy fromWrap:cell.item];
}

- (void)wrapCellDidSelectCandyPlaceholder:(WLWrapCell *)cell {
	[self.navigationController presentViewController:[self cameraViewController] animated:YES completion:nil];
}

- (void)wrapCell:(WLWrapCell *)cell didSelectWrap:(WLWrap *)wrap {
	WLWrapViewController* wrapController = [WLWrapViewController instantiate];
	wrapController.wrap = wrap;
	[self.navigationController pushViewController:wrapController animated:YES];
}

#pragma mark - WLQuickChatViewDelegate

- (void)quickChatView:(WLQuickChatView *)view didOpenChat:(WLWrap *)wrap {
    WLWrapViewController* wrapController = [WLWrapViewController instantiate];
	wrapController.wrap = wrap;
	NSArray* controllers = @[self, wrapController, [WLChatViewController instantiate:^(WLChatViewController *controller) {
        controller.wrap = wrap;
    }]];
    [self.navigationController setViewControllers:controllers animated:YES];
}

@end
