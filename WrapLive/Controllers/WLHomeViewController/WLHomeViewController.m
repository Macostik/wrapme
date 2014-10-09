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
#import "WLEntryNotifier.h"
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

@interface WLHomeViewController () <WLStillPictureViewControllerDelegate, WLEntryNotifyReceiver, WLNotificationReceiver, WLCreateWrapViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (weak, nonatomic) IBOutlet WLUserView *userView;
@property (strong, nonatomic) IBOutlet WLHomeViewSection *section;
@property (weak, nonatomic) IBOutlet WLSizeToFitLabel *notificationsLabel;
@property (weak, nonatomic) IBOutlet UIView *emailConfirmationView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (strong, nonatomic) UIImageView *noContentPlaceholder;
@property (assign, nonatomic) BOOL isShowPlaceholder;

@end

@implementation WLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[[WLUser notifier] addReceiver:self];
	[[WLWrap notifier] addReceiver:self];
	
    [[WLNotificationCenter defaultCenter] addReceiver:self];
    
    WLUserView* userView = self.userView;
	userView.avatarView.layer.borderWidth = 1;
	userView.avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    userView.user = [WLUser currentUser];
    
    [self.dataProvider setRefreshable];
    
    __weak WLHomeViewSection *section = self.section;
    section.entries.request = [WLWrapsRequest new];
    [section.entries resetEntries:[[WLUser currentUser] sortedWraps]];

    __weak __typeof(self)weakSelf = self;
    [section setChange:^(WLPaginatedSet* entries) {
        WLUser *user = [WLUser currentUser];
        weakSelf.isShowPlaceholder = ![self.section.entries.entries nonempty];
        if (user.firstTimeUse.boolValue && [user.wraps match:^BOOL(WLWrap *wrap) {
            return !wrap.isDefault.boolValue;
        }]) {
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.noContentPlaceholder removeFromSuperview];
}

- (void)setIsShowPlaceholder:(BOOL)isShowPlaceholder {
    if (_isShowPlaceholder != isShowPlaceholder) {
        _isShowPlaceholder = isShowPlaceholder;
        if (isShowPlaceholder) {
            [self showPlaceholder];
        } else {
            [self.noContentPlaceholder removeFromSuperview];
        }
    }
}

- (void)showPlaceholder {
    self.noContentPlaceholder = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"create_new_wrap"]];
    self.noContentPlaceholder.center = CGPointMake(self.view.center.x, self.view.center.y - 180) ;
    [self.view insertSubview:self.noContentPlaceholder atIndex:0];
    [super showPlaceholder];
}

- (void)updateEmailConfirmationView {
    BOOL confirmed = ![WLAuthorization currentAuthorization].unconfirmed_email.nonempty;
    UIView* view = self.emailConfirmationView;
    if (view.hidden != confirmed) {
        view.hidden = confirmed;
        self.topConstraint.constant = (confirmed ? self.navigationBar.height : view.bottom) - 20;
        [self.view layoutIfNeeded];
    }
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier userUpdated:(WLUser *)user {
    [self updateEmailConfirmationView];
}

- (void)notifier:(WLEntryNotifier *)notifier wrapUpdated:(WLWrap *)wrap {
    [self.section.entries resetEntries:[[WLUser currentUser] sortedWraps]];
}

- (void)notifier:(WLEntryNotifier *)notifier wrapAdded:(WLWrap *)wrap {
    [self.section.entries addEntry:wrap];
	self.collectionView.contentOffset = CGPointZero;
    self.isShowPlaceholder = ![self.section.entries.entries nonempty];
}

- (void)notifier:(WLEntryNotifier *)notifier wrapDeleted:(WLWrap *)wrap {
    [self.section.entries removeEntry:wrap];
    self.isShowPlaceholder = ![self.section.entries.entries nonempty];
}

- (void)notifier:(WLEntryNotifier*)notifier commentAdded:(WLComment*)comment {
	[self updateNotificationsLabel];
}

- (void)notifier:(WLEntryNotifier*)broadcaster commentDeleted:(WLComment *)comment {
	run_after(.5, ^{
		[self updateNotificationsLabel];
	});
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

@end
