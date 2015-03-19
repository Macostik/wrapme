//
//  WLHomeViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLOperationQueue.h"
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
#import "WLBadgeLabel.h"
#import "WLToast.h"
#import "WLUserView.h"
#import "WLWrapCell.h"
#import "WLWrapViewController.h"
#import "WLWrapsRequest.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLRemoteObjectHandler.h"
#import "WLPickerViewController.h"
#import "WLEditWrapViewController.h"
#import "WLUploadingView.h"
#import "WLUploadingQueue.h"
#import "WLAddressBook.h"
#import "WLIntroductionViewController.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLTouchView.h"

@interface WLHomeViewController () <WLEntryNotifyReceiver, WLPickerViewDelegate, WLWrapCellDelegate, WLIntroductionViewControllerDelegate, WLTouchViewDelegate>

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLHomeViewSection *section;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *emailConfirmationView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *notificationsLabel;
@property (weak, nonatomic) IBOutlet WLUploadingView *uploadingView;
@property (weak, nonatomic) IBOutlet UIView *createWrapTipView;
@property (weak, nonatomic) IBOutlet UIButton *createWrapButton;

@property (strong, nonatomic) WLWrap* chatSegueWrap;

@property (nonatomic) BOOL createWrapTipHidden;

@property (nonatomic) BOOL createWrapTipDelayedHiding;

@end

@implementation WLHomeViewController

- (void)dealloc {
    [[WLAddressBook addressBook] endCaching];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.createWrapTipHidden = YES;
    
    [[WLAddressBook addressBook] beginCaching];
    
    self.collectionView.contentInset = self.collectionView.scrollIndicatorInsets;
    
	[[WLUser notifier] addReceiver:self];
	[[WLWrap notifier] addReceiver:self];
    [[WLComment notifier] addReceiver:self];
	
    [[WLNotificationCenter defaultCenter] addReceiver:self];
    
    [self.dataProvider setRefreshable];
    
    __weak WLHomeViewSection *section = self.section;
    section.entries.request = [WLWrapsRequest new];
    [section.entries resetEntries:[[WLUser currentUser] sortedWraps]];

    __weak typeof(self)weakSelf = self;
    [section setChange:^(WLPaginatedSet* entries) {
        [weakSelf handleFirstUsage];
    }];
    
    [section setSelection:^(id entry) {
        [entry present];
    }];
    
    NSMutableOrderedSet* wraps = [[WLUser currentUser] sortedWraps];
    [section.entries resetEntries:wraps];
    if (wraps.nonempty) {
        [section refresh];
    }
    
    self.uploadingView.queue = [WLUploadingQueue queueForEntriesOfClass:[WLCandy class]];
}

- (void)setCreateWrapTipHidden:(BOOL)createWrapTipHidden {
    _createWrapTipHidden = createWrapTipHidden;
    if (self.createWrapTipView.hidden != createWrapTipHidden) {
        [self.createWrapTipView fade];
        self.createWrapTipView.hidden = createWrapTipHidden;
    }
    if (!createWrapTipHidden && !self.createWrapTipDelayedHiding) {
        [WLSession setObject:[NSDate date] key:@"WLCreateWrapTipShowDate"];
        if ([WLUser currentUser].wraps.nonempty) {
            self.createWrapTipDelayedHiding = YES;
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideCreateWrapTip) object:nil];
            [self performSelector:@selector(hideCreateWrapTip) withObject:nil afterDelay:10.0f];
        }
    }
}

- (void)hideCreateWrapTip {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideCreateWrapTip) object:nil];
    self.createWrapTipDelayedHiding = NO;
    self.createWrapTipHidden = YES;
}

- (BOOL)isCreateWrapTipHiddenWithWraps:(NSOrderedSet*)wraps {
    if (self.createWrapTipDelayedHiding) return NO;
    if (wraps.count == 0) return NO;
    NSDate *createWrapTipShowDate = [WLSession object:@"WLCreateWrapTipShowDate"];
    if (createWrapTipShowDate) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:createWrapTipShowDate toDate:[NSDate date] options:0];
        return components.day < 7;
    } else {
        return NO;
    }
}

- (void)handleFirstUsage {
    WLUser *user = [WLUser currentUser];
    NSOrderedSet *wraps = user.wraps;
    BOOL firstTimeUse = user.firstTimeUse;
    if (firstTimeUse) {
        static BOOL introductionShown = NO;
        if (!introductionShown) {
            introductionShown = YES;
            self.createWrapTipHidden = YES;
            WLIntroductionViewController *introduction = [[UIStoryboard storyboardNamed:WLIntroductionStoryboard] instantiateInitialViewController];
            introduction.modalPresentationStyle = UIModalPresentationCustom;
            introduction.delegate = self;
            [self presentViewController:introduction animated:YES completion:nil];
        } else if (!self.presentedViewController) {
            self.createWrapTipHidden = [self isCreateWrapTipHiddenWithWraps:wraps];
        }
        
    } else {
        self.createWrapTipHidden = [self isCreateWrapTipHiddenWithWraps:wraps];
    }
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    [self.dataProvider reload];
    [self updateNotificationsLabel];
    [self updateEmailConfirmationView:NO];
    [WLRemoteObjectHandler sharedObject].isLoaded = [self isViewLoaded];
    [self.uploadingView update];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self hideCreateWrapTip];
}

- (void)updateEmailConfirmationView:(BOOL)animated {
    BOOL hidden = ([[WLSession confirmationDate] isToday] || ![[WLAuthorization currentAuthorization] unconfirmed_email].nonempty);
    [self setEmailConfirmationViewHidden:hidden animated:animated];
}

- (void)setEmailConfirmationViewHidden:(BOOL)hidden animated:(BOOL)animated {
    CGFloat constraint = hidden ? 0 : self.emailConfirmationView.height;
    if (self.topConstraint.constant != constraint) {
        self.topConstraint.constant = constraint;
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

- (void)openCameraAnimated:(BOOL)animated startFromGallery:(BOOL)startFromGallery {
    WLWrap *wrap = self.section.wrap;
    if (wrap) {
        WLStillPictureViewController *stillPictureViewController = [WLStillPictureViewController instantiate:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
        stillPictureViewController.wrap = wrap;
        stillPictureViewController.mode = WLStillPictureModeDefault;
        stillPictureViewController.delegate = self;
        stillPictureViewController.startFromGallery = startFromGallery;
        __weak typeof(self)weakSelf = self;
        [self presentViewController:stillPictureViewController animated:animated completion:^{
            [weakSelf stillPictureViewController:stillPictureViewController didSelectWrap:wrap];
        }];
    } else {
        [self createWrap:nil];
    }
}

#pragma mark - WLWrapCellDelegate 

- (void)wrapCell:(WLWrapCell *)wrapCell didDeleteWrap:(WLWrap *)wrap {
    if (wrap.valid) {
        WLEditWrapViewController *editWrapViewController = [[WLEditWrapViewController alloc] initWithNibName:@"WLWrapOptionsViewController"
                                                                                                      bundle:nil];
        editWrapViewController.wrap = wrap;
        [self presentViewController:editWrapViewController animated:YES completion:nil];
    }
}

- (void)wrapCell:(WLWrapCell *)wrapCell forWrap:(WLWrap *)wrap notifyChatButtonClicked:(id)sender {
    self.chatSegueWrap = wrap;
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
}

- (void)notifier:(WLEntryNotifier *)notifier wrapDeleted:(WLWrap *)wrap {
    [self.section.entries removeEntry:wrap];
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

- (void)updateNotificationsLabel {
    self.notificationsLabel.intValue = [[WLUser currentUser] unreadNotificationsCount];
}

#pragma mark - Actions

- (IBAction)resendConfirmation:(id)sender {
    [[WLResendConfirmationRequest request] send:^(id object) {
        WLToastAppearance* appearance = [WLToastAppearance appearance];
        appearance.shouldShowIcon = NO;
        appearance.contentMode = UIViewContentModeCenter;
        [WLToast showWithMessage:WLLS(@"Confirmation resend. Please, check you e-mail.") appearance:appearance];
    } failure:^(NSError *error) {
    }];
}

- (IBAction)createWrap:(id)sender {
    __weak WLStillPictureViewController *stillPictureViewController = [WLStillPictureViewController instantiate:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
    stillPictureViewController.mode = WLStillPictureModeDefault;
    stillPictureViewController.delegate = self;
    
    __weak __typeof(self)weakSelf = self;
    WLCreateWrapViewController *createWrapViewController = [WLCreateWrapViewController new];
    [createWrapViewController setCreateHandler:^(WLWrap *wrap) {
        stillPictureViewController.wrap = wrap;
        [stillPictureViewController dismissViewControllerAnimated:YES completion:NULL];
    }];
    
    [createWrapViewController setCancelHandler:^{
        [weakSelf dismissViewControllerAnimated:YES completion:NULL];
    }];
    
    [self presentViewController:stillPictureViewController animated:YES completion:^{
        [stillPictureViewController presentViewController:createWrapViewController animated:YES completion:nil];
    }];
}

- (IBAction)addPhoto:(id)sender {
    WLIntroductionViewController *introduction = [[UIStoryboard storyboardNamed:WLIntroductionStoryboard] instantiateInitialViewController];
    introduction.modalPresentationStyle = UIModalPresentationCustom;
    introduction.delegate = self;
    [self presentViewController:introduction animated:YES completion:nil];
//    [self openCameraAnimated:YES startFromGallery:NO];
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

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didSelectWrap:(WLWrap *)wrap {
    if (wrap) {
        WLPickerViewController *pickerViewController = [[WLPickerViewController alloc] initWithWrap:wrap delegate:self];
        [controller presentViewController:pickerViewController animated:YES completion:nil];
    } else {
        [self createWrapWithStillPictureViewController:controller];
    }
}

#pragma mark - WLPickerViewDelegate

- (void)createWrapWithStillPictureViewController:(WLStillPictureViewController*)stillPictureViewController {
    WLCreateWrapViewController *createWrapViewController = [WLCreateWrapViewController new];
    [createWrapViewController setCreateHandler:^(WLWrap *wrap) {
        stillPictureViewController.wrap = wrap;
        [stillPictureViewController dismissViewControllerAnimated:YES completion:NULL];
    }];
    [createWrapViewController setCancelHandler:^{
        [stillPictureViewController dismissViewControllerAnimated:YES completion:NULL];
    }];
    [stillPictureViewController presentViewController:createWrapViewController animated:YES completion:nil];
}

- (void)pickerViewControllerNewWrapClicked:(WLPickerViewController *)pickerViewController {
    WLStillPictureViewController* stillPictureViewController = (id)pickerViewController.presentingViewController;
    __weak typeof(self)weakSelf = self;
    [stillPictureViewController dismissViewControllerAnimated:YES completion:^{
        [weakSelf createWrapWithStillPictureViewController:stillPictureViewController];
    }];
}

- (void)pickerViewController:(WLPickerViewController *)pickerViewController didSelectWrap:(WLWrap *)wrap {
    WLStillPictureViewController* stillPictureViewController = (id)pickerViewController.presentingViewController;
    stillPictureViewController.wrap = wrap;
}

- (void)pickerViewControllerDidCancel:(WLPickerViewController *)pickerViewController {
    [pickerViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

// MARK: - WLIntroductionViewControllerDelegate

- (void)introductionViewControllerDidFinish:(WLIntroductionViewController *)controller {
    __weak typeof(self)weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        weakSelf.createWrapTipHidden = [self isCreateWrapTipHiddenWithWraps:[WLUser currentUser].wraps];
    }];
}

// MARK: - WLTouchViewDelegate

- (void)touchViewDidReceiveTouch:(WLTouchView *)touchView {
    [self hideCreateWrapTip];
}

- (NSSet *)touchViewExclusionRects:(WLTouchView *)touchView {
    return [NSSet setWithObject:[NSValue valueWithCGRect:[touchView convertRect:self.createWrapButton.bounds fromView:self.createWrapButton]]];
}

@end
