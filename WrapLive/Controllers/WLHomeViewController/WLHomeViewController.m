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
#import "WLNotificationCenter.h"
#import "WLNotification.h"
#import "UIView+AnimationHelper.h"
#import "AsynchronousOperation.h"
#import "WLPaginatedSet.h"
#import "WLAPIManager.h"
#import "WLWrapsRequest.h"
#import "WLCollectionViewDataProvider.h"
#import "WLHomeViewSection.h"
#import "WLNavigation.h"
#import "WLUserView.h"
#import "WLEntryFetching.h"
#import "WLServerTime.h"

@interface WLHomeViewController () <WLStillPictureViewControllerDelegate, WLWrapBroadcastReceiver, WLNotificationReceiver, WLCreateWrapViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *noWrapsView;
@property (weak, nonatomic) WLRefresher *refresher;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (weak, nonatomic) WLLoadingView *splash;
@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (weak, nonatomic) IBOutlet WLUserView *userView;
@property (strong, nonatomic) IBOutlet WLHomeViewSection *section;
@property (weak, nonatomic) IBOutlet UILabel *notificationsLabel;

@end

@implementation WLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
	self.userView.avatarView.layer.borderWidth = 1;
	self.userView.avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.userView.user = [WLUser currentUser];
    
    self.section.entries.request = [WLWrapsRequest new];
    [self.section.entries resetEntries:[[WLUser currentUser] sortedWraps]];
    
    self.splash = [[WLLoadingView splash] showInView:self.view];
    
	self.collectionView.hidden = YES;
	self.noWrapsView.hidden = YES;
	[self.dataProvider setRefreshable];
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
	[[WLNotificationCenter defaultCenter] addReceiver:self];
    
    __weak typeof(self)weakSelf = self;
    [self.section setChange:^(WLPaginatedSet* entries) {
        BOOL hasWraps = entries.entries.nonempty;
        weakSelf.collectionView.hidden = !hasWraps;
        weakSelf.noWrapsView.hidden = hasWraps;
        [weakSelf finishLoadingAnimation];
        [weakSelf showLatestWrap];
    }];
    
    [self.section setSelection:^(id entry) {
        [entry present];
    }];
    
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.userView update];
    NSOrderedSet* wraps = [[WLUser currentUser] sortedWraps];
	if (self.collectionView.hidden) {
		[self.section refresh];
        if (wraps.nonempty) {
            [self.section.entries resetEntries:wraps];
        }
	} else {
        [self.section.entries resetEntries:wraps];
    }
    [self updateNotificationsLabel];
}

- (CGFloat)toastAppearanceHeight:(WLToast *)toast {
	return 84.0f;
}

- (UIViewController *)shakePresentedViewController {
	return self.section.wrap ? [self cameraViewController] : nil;
}

- (id)cameraViewController {
	__weak typeof(self)weakSelf = self;
	return [WLStillPictureViewController instantiate:^(WLStillPictureViewController* controller) {
		controller.wrap = weakSelf.section.wrap;
		controller.delegate = self;
		controller.mode = WLCameraModeCandy;
	}];
}

- (void)showLatestWrap {
    WLUser * user = [WLUser currentUser];
	if (user.signInCount.integerValue == 1 && self.section.entries.entries.nonempty) {
        __weak typeof(self)weakSelf = self;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [weakSelf.section.wrap present];
        });
	}
}

- (void)finishLoadingAnimation {
	if (self.splash.superview) {
		__weak typeof(self)weakSelf = self;
		[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
			weakSelf.splash.alpha = 0.0f;
		} completion:^(BOOL finished) {
			[weakSelf.splash hide];
		}];
	}
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapChanged:(WLWrap *)wrap {
    [self.section.entries resetEntries:[[WLUser currentUser] sortedWraps]];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapCreated:(WLWrap *)wrap {
    [self.section.entries addEntry:wrap];
	self.collectionView.contentOffset = CGPointZero;
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapRemoved:(WLWrap *)wrap {
    [self.section.entries removeEntry:wrap];
}

#pragma mark - WLNotificationReceiver

- (void)handleRemoteNotification:(WLNotification*)notification {
    if ([notification deletion]) {
        return;
    }
    void (^showNotificationBlock)(void) = ^{
        WLNotificationType type = notification.type;
		if (type == WLNotificationContributorAddition) {
            [notification.wrap present];
		} else if (type == WLNotificationImageCandyAddition ||
                   type == WLNotificationChatCandyAddition  ||
                   type == WLNotificationCandyCommentAddition) {
            [notification.candy present];
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

- (void)broadcaster:(WLNotificationCenter *)broadcaster didReceiveRemoteNotification:(WLNotification *)notification {
	[self handleRemoteNotification:notification];
	broadcaster.pendingRemoteNotification = nil;
}

static CGFloat WLNotificationsLabelSize = 22;

- (void)updateNotificationsLabel {
    UILabel* label = self.notificationsLabel;
    NSUInteger count = [[[WLNotificationCenter defaultCenter] notificationEntries:YES] count];
    label.hidden = count == 0;
    label.text = [NSString stringWithFormat:@"%lu", (unsigned long)count];
    label.width = MAX(WLNotificationsLabelSize, [label sizeThatFits:CGSizeMake(CGFLOAT_MAX, WLNotificationsLabelSize)].width + 12);
}

#pragma mark - Actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isWrapCameraSegue]) {
		WLStillPictureViewController* controller = segue.destinationViewController;
		controller.delegate = self;
		controller.mode = WLCameraModeWrapCreation;
	} else if ([segue isCameraSegue]) {
        WLStillPictureViewController* controller = segue.destinationViewController;
        controller.wrap = self.section.wrap;
		controller.delegate = self;
		controller.mode = WLCameraModeCandy;
    }
}

- (IBAction)createNewWrap:(id)sender {
	WLCreateWrapViewController* controller = [WLCreateWrapViewController instantiate];
	[controller presentInViewController:self transition:WLWrapTransitionFromBottom];
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    WLWrap* wrap = controller.wrap;
    if (wrap) {
        [wrap uploadPictures:pictures];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        WLCreateWrapViewController* createWrapViewController = [WLCreateWrapViewController instantiate];
        createWrapViewController.pictures = pictures;
        createWrapViewController.delegate = self;
        [controller.cameraNavigationController pushViewController:createWrapViewController animated:YES];
    }
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WLCreateWrapViewControllerDelegate

- (void)createWrapViewControllerDidCancel:(WLCreateWrapViewController *)controller {
    [controller.navigationController popViewControllerAnimated:YES];
}

- (void)createWrapViewController:(WLCreateWrapViewController *)controller didCreateWrap:(WLWrap *)wrap {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster commentCreated:(WLComment*)comment {
    [self updateNotificationsLabel];
}

@end
