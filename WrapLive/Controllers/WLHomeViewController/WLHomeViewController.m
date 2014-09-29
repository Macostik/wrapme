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
#import "WLResendConfirmationRequest.h"
#import "WLSizeToFitLabel.h"

@interface WLHomeViewController () <WLStillPictureViewControllerDelegate, WLWrapBroadcastReceiver, WLNotificationReceiver, WLCreateWrapViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (weak, nonatomic) IBOutlet WLUserView *userView;
@property (strong, nonatomic) IBOutlet WLHomeViewSection *section;
@property (weak, nonatomic) IBOutlet WLSizeToFitLabel *notificationsLabel;
@property (weak, nonatomic) IBOutlet UIView *emailConfirmationView;

@end

@implementation WLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[WLWrapBroadcaster broadcaster] addReceiver:self];
    [[WLNotificationCenter defaultCenter] addReceiver:self];
    
    WLUserView* userView = self.userView;
	userView.avatarView.layer.borderWidth = 1;
	userView.avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    userView.user = [WLUser currentUser];
    
    [self.dataProvider setRefreshable];
    
    __weak WLHomeViewSection *section = self.section;
    section.entries.request = [WLWrapsRequest new];
    [section.entries resetEntries:[[WLUser currentUser] sortedWraps]];
    
    [section setChange:^(WLPaginatedSet* entries) {
        WLUser *user = [WLUser currentUser];
        if (user.firstTimeUse.boolValue && section.wrap) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                [section.wrap present];
            });
        }
    }];
    
    [section setSelection:^(id entry) {
        [entry present];
    }];
    
    NSMutableOrderedSet* wraps = [[WLUser currentUser] sortedWraps];
    [section.entries resetEntries:wraps];
    if (wraps.nonempty) {
        [section refresh];
    }
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.userView update];
    [self.dataProvider reload];
    [self updateNotificationsLabel];
    [self updateEmailConfirmationView];
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

- (void)updateEmailConfirmationView {
    BOOL confirmed = ![WLAuthorization currentAuthorization].unconfirmed_email.nonempty;
    UIView* view = self.emailConfirmationView;
    if (view.hidden != confirmed) {
        view.hidden = confirmed;
        CGFloat y = confirmed ? self.navigationBar.height : view.bottom;
        [self.collectionView setY:y height:self.view.height - y];
    }
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster userChanged:(WLUser *)user {
    [self updateEmailConfirmationView];
}

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
    if (notification.event == WLEventDelete) return;
    
	UIViewController* presentedViewController = self.navigationController.presentedViewController;
	if (presentedViewController) {
		__weak typeof(self)weakSelf = self;
		[UIAlertView showWithTitle:@"View notification"
						   message:@"Incompleted data can be lost. Do you want to continue?"
							action:@"Continue"
							cancel:@"Cancel"
						completion:^{
			[weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
			[notification.targetEntry present];
		}];
	} else {
		[notification.targetEntry present];
	}
}

- (void)broadcaster:(WLNotificationCenter *)broadcaster didReceiveRemoteNotification:(WLNotification *)notification {
    [self handleRemoteNotification:notification];
	broadcaster.pendingRemoteNotification = nil;
}

- (void)updateNotificationsLabel {
    self.notificationsLabel.intValue = [[WLUser currentUser] unreadNotificationsCount];
}

#pragma mark - Actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isWrapCameraSegue]) {
		WLStillPictureViewController* controller = segue.destinationViewController;
		controller.delegate = self;
		controller.mode = WLCameraModeCandy;
        controller.editable = NO;
	} else if ([segue isCameraSegue]) {
        WLStillPictureViewController* controller = segue.destinationViewController;
        controller.wrap = self.section.wrap;
		controller.delegate = self;
		controller.mode = WLCameraModeCandy;
    }
}

- (IBAction)resendConfirmation:(id)sender {
    [[WLResendConfirmationRequest request] send:^(id object) {
        WLToastAppearance* appearance = [WLToastAppearance appearance];
        appearance.shouldShowIcon = NO;
        appearance.contentMode = UIViewContentModeCenter;
        [WLToast showWithMessage:@"Confirmation resend. Please, check you e-mail." appearance:appearance];
    } failure:^(NSError *error) {
    }];
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

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster commentRemoved:(WLComment *)comment {
    run_after(.5, ^{
        [self updateNotificationsLabel];
    });
    
}

@end
