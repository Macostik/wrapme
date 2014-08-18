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
#import "WLPaginatedSet.h"
#import "WLAPIManager.h"
#import "WLWrapsRequest.h"
#import "WLCollectionViewDataProvider.h"
#import "WLHomeViewSection.h"
#import "WLNavigation.h"

@interface WLHomeViewController () <WLStillPictureViewControllerDelegate, WLWrapBroadcastReceiver, WLNotificationReceiver>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *noWrapsView;
@property (weak, nonatomic) WLRefresher *refresher;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (weak, nonatomic) WLLoadingView *splash;
@property (weak, nonatomic) IBOutlet UIButton *createWrapButton;
@property (weak, nonatomic) IBOutlet WLImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet WLQuickChatView *quickChatView;
@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLHomeViewSection *section;

@end

@implementation WLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.section.entries.request = [WLWrapsRequest new];
    [self.section.entries resetEntries:[[WLUser currentUser] sortedWraps]];
    
    self.splash = [[WLLoadingView splash] showInView:self.view];
    
    [self setNavigationBarHidden:YES animated:NO];
	self.createWrapButton.transform = CGAffineTransformMakeTranslation(0, self.createWrapButton.height);
	self.collectionView.hidden = YES;
	self.noWrapsView.hidden = YES;
	[self.dataProvider setRefreshable];
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
	[[WLNotificationBroadcaster broadcaster] addReceiver:self];
    
    __weak typeof(self)weakSelf = self;
    [self.section setChange:^(WLPaginatedSet* entries) {
        weakSelf.quickChatView.wrap = weakSelf.section.wrap;
        BOOL hasWraps = entries.entries.nonempty;
        weakSelf.quickChatView.hidden = !hasWraps;
        weakSelf.collectionView.hidden = !hasWraps;
        weakSelf.noWrapsView.hidden = hasWraps;
        [weakSelf setNavigationBarHidden:!hasWraps animated:YES];
        [weakSelf finishLoadingAnimation];
    }];
    
    [self.section setSelection:^(id entry) {
        [entry presentInViewController:weakSelf];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    self.avatarImageView.circled = YES;
	self.avatarImageView.layer.borderWidth = 1;
	self.avatarImageView.layer.borderColor = [UIColor whiteColor].CGColor;
	self.avatarImageView.url = [WLUser currentUser].picture.small;
    NSOrderedSet* wraps = [[WLUser currentUser] sortedWraps];
	if (self.collectionView.hidden) {
        self.section.entries.request.type = WLPaginatedRequestTypeNewer;
		[self.section.entries send:^(NSOrderedSet *orderedSet) {
        } failure:^(NSError *error) {
        }];
        if (wraps.nonempty) {
            [self.section.entries resetEntries:wraps];
        }
	} else {
        [self.section.entries resetEntries:wraps];
    }
}

- (CGFloat)toastAppearanceHeight:(WLToast *)toast {
	return 84.0f;
}

- (UIViewController *)shakePresentedViewController {
	return self.section.entries.entries.nonempty ? [self cameraViewController] : nil;
}

- (id)cameraViewController {
	__weak typeof(self)weakSelf = self;
	return [WLStillPictureViewController instantiate:^(WLStillPictureViewController* controller) {
		controller.wrap = weakSelf.section.wrap;
		controller.delegate = self;
		controller.mode = WLCameraModeCandy;
	}];
}

//- (void)fetchWraps:(BOOL)refresh {
//    if (!self.section.entries.entries.nonempty) {
//        [self fetchFreshWraps];
//    } else if (refresh) {
//        [self refreshWraps];
//    } else {
//        [self appendWraps];
//    }
//}

//- (void)fetchFreshWraps {
//    if (self.section.entries.request.loading) return;
//    __weak typeof(self)weakSelf = self;
//    self.section.entries.request.type = WLPaginatedRequestTypeFresh;
//    [self.section.entries send:^(NSOrderedSet *orderedSet) {
//        [weakSelf showLatestWrap];
//        [weakSelf updateWraps];
//        if ([orderedSet count] != 50) {
//            weakSelf.showLoadingView = NO;
//        }
//    } failure:^(NSError *error) {
//        if (weakSelf.isOnTopOfNagvigation) {
//            [error showIgnoringNetworkError];
//        }
//        [weakSelf updateWraps];
//    }];
//}
//
//- (void)refreshWraps {
//    if (self.section.entries.request.loading) return;
//    __weak typeof(self)weakSelf = self;
//    self.section.entries.request.type = WLPaginatedRequestTypeNewer;
//    [self.section.entries send:^(NSOrderedSet *orderedSet) {
//        [weakSelf updateWraps];
//        [weakSelf.refresher endRefreshing];
//    } failure:^(NSError *error) {
//        [weakSelf.refresher endRefreshing];
//        if (weakSelf.isOnTopOfNagvigation) {
//            [error showIgnoringNetworkError];
//        }
//    }];
//}
//
//- (void)appendWraps {
//    if (self.section.entries.request.loading) return;
//    __weak typeof(self)weakSelf = self;
//    self.section.entries.request.type = WLPaginatedRequestTypeOlder;
//    [self.section.entries send:^(NSOrderedSet *orderedSet) {
//        [weakSelf updateWraps];
//        if (weakSelf.section.entries.completed) {
//            weakSelf.showLoadingView = NO;
//        }
//    } failure:^(NSError *error) {
//        if (weakSelf.isOnTopOfNagvigation) {
//            [error showIgnoringNetworkError];
//        }
//    }];
//}

- (void)showLatestWrap {
    WLUser * user = [WLUser currentUser];
    static BOOL firstWrapShown = NO;
	if (!firstWrapShown && user.signInCount.integerValue == 1 && self.section.entries.entries.nonempty) {
		WLWrapViewController* wrapController = [WLWrapViewController instantiate];
		wrapController.wrap = [self.section.entries.entries firstObject];
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
//
//- (void)updateWraps {
//	
//	BOOL hasWraps = _wraps.entries.nonempty;
//	
//    self.quickChatView.hidden = !hasWraps;
//    
//    self.topWrap = [self.wraps.entries firstObject];
//	
//	self.collectionView.hidden = !hasWraps;
//	self.noWrapsView.hidden = hasWraps;
//	[self.collectionView reloadData];
//	
//	[self setNavigationBarHidden:!hasWraps animated:YES];
//    
//    [self finishLoadingAnimation];
//}

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated {
    __weak typeof(self)weakSelf = self;
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, hidden ? -weakSelf.navigationBar.height : 0);
    if (!CGAffineTransformEqualToTransform(self.navigationBar.transform, transform)) {
        [UIView performAnimated:animated animation:^{
            weakSelf.navigationBar.transform = transform;
        }];
    }
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapChanged:(WLWrap *)wrap {
    [self.section.entries resetEntries:[[WLUser currentUser] sortedWraps]];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapCreated:(WLWrap *)wrap {
    [self.section.entries resetEntries:[[WLUser currentUser] sortedWraps]];
	self.collectionView.contentOffset = CGPointZero;
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapRemoved:(WLWrap *)wrap {
    [self.section.entries resetEntries:[[WLUser currentUser] sortedWraps]];
}

#pragma mark - WLNotificationReceiver

- (void)handleRemoteNotification:(WLNotification*)notification {
    if ([notification deletion]) {
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    void (^showNotificationBlock)(void) = ^{
        WLWrap* wrap = notification.wrap;
        WLNotificationType type = notification.type;
		if (type == WLNotificationContributorAddition) {
            [wrap presentInViewController:weakSelf];
		} else if (type == WLNotificationImageCandyAddition || type == WLNotificationChatCandyAddition || type == WLNotificationCandyCommentAddition) {
            [notification.candy presentInViewController:weakSelf];
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
		controller.wrap = self.section.wrap;
		controller.delegate = self;
		controller.mode = WLCameraModeCandy;
	}
}

- (IBAction)typeMessage:(UIButton *)sender {
	WLChatViewController * chatController = [WLChatViewController instantiate];
	chatController.wrap = self.section.wrap;
	chatController.shouldShowKeyboard = YES;
	[self.navigationController pushViewController:chatController animated:YES];
}

- (IBAction)createNewWrap:(id)sender {
	WLCreateWrapViewController* controller = [WLCreateWrapViewController instantiate];
	[controller presentInViewController:self transition:WLWrapTransitionFromBottom];
}

#pragma mark - UICollectionViewDelegate

//- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
//	return [self.wraps.entries count];
//}
//
//- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
//	WLWrap* wrap = [self.wraps.entries tryObjectAtIndex:indexPath.row];
//	WLWrapCell* cell = nil;
//	if (indexPath.row == 0) {
//		static NSString* topWrapCellIdentifier = @"WLTopWrapCell";
//		cell = [collectionView dequeueReusableCellWithReuseIdentifier:topWrapCellIdentifier forIndexPath:indexPath];
//		cell.item = wrap;
//		cell.candies = self.candies;
//	} else {
//		static NSString* wrapCellIdentifier = @"WLWrapCell";
//		cell = [collectionView dequeueReusableCellWithReuseIdentifier:wrapCellIdentifier forIndexPath:indexPath];
//		cell.item = wrap;
//	}
//	cell.delegate = self;
//	return cell;
//}
//
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
//    CGFloat height = 50;
//	if (indexPath.row == 0) {
//		height = [self.candies count] > WLHomeTopWrapCandiesLimit_2 ? 324 : 218;
//	}
//	return CGSizeMake(collectionView.width, height);
//}
//
//- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
//	[self appendWraps];
//    static NSString* identifier = @"WLLoadingView";
//    return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
//}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if (self.refresher.refreshing) {
		[self.refresher endRefreshing];
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

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    WLWrap* wrap = controller.wrap ? : self.section.wrap;
    [wrap uploadPictures:pictures];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
