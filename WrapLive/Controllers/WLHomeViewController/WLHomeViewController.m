//
//  WLHomeViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "AsynchronousOperation.h"
#import "NSArray+Additions.h"
#import "NSDate+Formatting.h"
#import "NSString+Additions.h"
#import "UIActionSheet+Blocks.h"
#import "UIAlertView+Blocks.h"
#import "UIColor+CustomColors.h"
#import "UIFont+CustomFonts.h"
#import "UILabel+Additions.h"
#import "UIView+AnimationHelper.h"
#import "UIView+Shorthand.h"
#import "UIViewController+Additions.h"
#import "WLAPIManager.h"
#import "WLCameraViewController.h"
#import "WLCandyViewController.h"
#import "WLChatViewController.h"
#import "WLCollectionViewDataProvider.h"
#import "WLComment.h"
#import "WLCreateWrapViewController.h"
#import "WLEntryManager.h"
#import "WLEntryNotifier.h"
#import "WLHomeViewController.h"
#import "WLHomeViewSection.h"
#import "WLImageCache.h"
#import "WLImageFetcher.h"
#import "WLLoadingView.h"
#import "WLNavigation.h"
#import "WLNotification.h"
#import "WLNotificationCenter.h"
#import "WLPaginatedSet.h"
#import "WLRefresher.h"
#import "WLResendConfirmationRequest.h"
#import "WLSession.h"
#import "WLSizeToFitLabel.h"
#import "WLStillPictureViewController.h"
#import "WLToast.h"
#import "WLUserView.h"
#import "WLWrapCell.h"
#import "WLWrapViewController.h"
#import "WLWrapsRequest.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLActionViewController.h"

static NSString *const WLTimeLineKey = @"WLTimeLineKey";
static NSString *const WLUnconfirmedEmailKey = @"WLUnconfirmedEmailKey";

@interface WLHomeViewController () <WLStillPictureViewControllerDelegate, WLEntryNotifyReceiver, WLNotificationReceiver>

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLHomeViewSection *section;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *emailConfirmationView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (weak, nonatomic) IBOutlet WLSizeToFitLabel *notificationsLabel;
@property (weak, nonatomic) IBOutlet WLUserView *userView;

@end

@implementation WLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
        weakSelf.showsPlaceholderView = entries.completed && ![entries.entries nonempty];
        if (user.firstTimeUse && [user.wraps match:^BOOL(WLWrap *wrap) {
            return !wrap.isDefault.boolValue;
        }]) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                [section.wrap present];
            });
        }
    }];
    
    [section setSelection:^(id entry) {
        if ([entry isKindOfClass:[WLCandy class]]) {
            [[entry wrap] present];
        } else {
            [entry present];
        }
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
    [self updateEmailConfirmationView:NO];
}

- (UINib *)placeholderViewNib {
    return [UINib nibWithNibName:@"WLHomePlaceholderView" bundle:nil];
}

- (void)updateEmailConfirmationView:(BOOL)animated {
    BOOL hidden = ([[WLSession confirmationDate] isToday] || ![[WLAuthorization currentAuthorization] unconfirmed_email].nonempty);
    [self setEmailConfirmationViewHidden:hidden animated:animated];
}

- (void)setEmailConfirmationViewHidden:(BOOL)hidden animated:(BOOL)animated {
    UIView* view = self.emailConfirmationView;
    if (view.hidden != hidden) {
        view.hidden = hidden;
        self.topConstraint.constant = (hidden ? self.navigationBar.height : self.navigationBar.height + view.height) - 20;
        __weak typeof(self)weakSelf = self;
        [UIView performAnimated:animated animation:^{
            [weakSelf.view layoutIfNeeded];
        }];
        if (!hidden) {
            [self deadlineEmailConfirmationView];
        }
    }
}

- (void)deadlineEmailConfirmationView {
    [WLSession setConfirmationDate:[NSDate now]];
    [self performSelector:@selector(hideConfirmationEmailView) withObject:nil afterDelay:15.0f];
}

- (void)hideConfirmationEmailView {
    [self setEmailConfirmationViewHidden:YES animated:YES];
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier userUpdated:(WLUser *)user {
    [self updateEmailConfirmationView:YES];
}

- (void)notifier:(WLEntryNotifier *)notifier wrapUpdated:(WLWrap *)wrap {
    [self.section.entries resetEntries:[[WLUser currentUser] sortedWraps]];
}

- (void)notifier:(WLEntryNotifier *)notifier wrapAdded:(WLWrap *)wrap {
    [self.section.entries addEntry:wrap];
	self.collectionView.contentOffset = CGPointZero;
    self.showsPlaceholderView = ![self.section.entries.entries nonempty];
}

- (void)notifier:(WLEntryNotifier *)notifier wrapDeleted:(WLWrap *)wrap {
    [self.section.entries removeEntry:wrap];
    self.showsPlaceholderView = ![self.section.entries.entries nonempty];
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
		[notification.targetEntry present:NO];
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

- (IBAction)resendConfirmation:(id)sender {
    [[WLResendConfirmationRequest request] send:^(id object) {
        WLToastAppearance* appearance = [WLToastAppearance appearance];
        appearance.shouldShowIcon = NO;
        appearance.contentMode = UIViewContentModeCenter;
        [WLToast showWithMessage:@"Confirmation resend. Please, check you e-mail." appearance:appearance];
    } failure:^(NSError *error) {
    }];
}

- (IBAction)createWrap:(id)sender {
    __weak WLStillPictureViewController *controller = [WLStillPictureViewController instantiate:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
    controller.mode = WLCameraModeCandy;
    controller.delegate = self;
    [controller willCreateWrap];
    
    [self.navigationController presentViewController:controller animated:YES completion:NULL];
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    WLWrap* wrap = controller.wrap;
    if (wrap) {
        [wrap uploadPictures:pictures];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
