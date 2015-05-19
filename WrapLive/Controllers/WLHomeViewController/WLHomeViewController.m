//
//  WLHomeViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLOperationQueue.h"
#import "UIActionSheet+Blocks.h"
#import "UIAlertView+Blocks.h"
#import "UIFont+CustomFonts.h"
#import "UILabel+Additions.h"
#import "UIView+AnimationHelper.h"
#import "WLCandyViewController.h"
#import "WLChatViewController.h"
#import "WLHomeDataSource.h"
#import "WLCreateWrapViewController.h"
#import "WLHomeViewController.h"
#import "WLLoadingView.h"
#import "WLNavigationHelper.h"
#import "WLRefresher.h"
#import "WLBadgeLabel.h"
#import "WLToast.h"
#import "WLUserView.h"
#import "WLWrapCell.h"
#import "WLWrapViewController.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLRemoteEntryHandler.h"
#import "WLPickerViewController.h"
#import "WLEditWrapViewController.h"
#import "WLUploadingView.h"
#import "WLAddressBook.h"
#import "WLIntroductionViewController.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLTouchView.h"
#import "WLChronologicalEntryPresenter.h"
#import "WLCollectionView.h"
#import "WLGradientView.h"

@interface WLHomeViewController () <WLPickerViewDelegate, WLWrapCellDelegate, WLIntroductionViewControllerDelegate, WLTouchViewDelegate>

@property (strong, nonatomic) IBOutlet WLHomeDataSource *dataSource;
@property (weak, nonatomic) IBOutlet WLCollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *emailConfirmationView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *hiddenEmailConfirmationConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *visibleEmailConfirmationConstraint;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *notificationsLabel;
@property (weak, nonatomic) IBOutlet WLUploadingView *uploadingView;
@property (weak, nonatomic) IBOutlet UIView *createWrapTipView;
@property (weak, nonatomic) IBOutlet UIButton *createWrapButton;
@property (weak, nonatomic) IBOutlet WLLabel *verificationEmailLabel;

@property (weak, nonatomic) WLWrap* chatSegueWrap;

@property (nonatomic) BOOL createWrapTipHidden;

@end

@implementation WLHomeViewController

- (void)dealloc {
    [[WLAddressBook addressBook] endCaching];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self)weakSelf = self;
    
    __weak WLOperationQueue *queue = [WLOperationQueue queueNamed:WLOperationFetchingDataQueue];
    [queue setStartQueueBlock:^{
        weakSelf.collectionView.stopReloadingData = YES;
    }];
    [queue setFinishQueueBlock:^{
        weakSelf.collectionView.stopReloadingData = NO;
        queue.startQueueBlock = nil;
        queue.finishQueueBlock = nil;
    }];
    
    self.createWrapTipHidden = YES;
    
    [[WLAddressBook addressBook] beginCaching];
    
    self.collectionView.contentInset = self.collectionView.scrollIndicatorInsets;
    
    [self addNotifyReceivers];
    
    __weak WLHomeDataSource *dataSource = self.dataSource;
    [dataSource setRefreshable];
    [dataSource setItemSizeBlock:^CGSize(WLWrap *wrap, NSUInteger index) {
        CGFloat height = 50;
        if (index == 0) {
            int size = (weakSelf.collectionView.bounds.size.width - 2.0f)/3.0f;;
            height = 75 + ([dataSource.wrap.candies count] > WLHomeTopWrapCandiesLimit_2 ? 2*size : size);
        }
        return CGSizeMake(weakSelf.collectionView.width, height);
    }];
    
    [dataSource setCellIdentifierForItemBlock:^NSString *(WLWrap *wrap, NSUInteger index) {
        return (index == 0) ? @"WLTopWrapCell" : @"WLWrapCell";
    }];
    
    NSMutableOrderedSet* wraps = [[WLUser currentUser] sortedWraps];
    dataSource.items = [WLPaginatedSet setWithEntries:wraps request:[WLWrapsRequest new]];
    
    [dataSource setSelectionBlock:^(id entry) {
        [WLChronologicalEntryPresenter presentEntry:entry animated:NO];
    }];
    
    if (wraps.nonempty) {
        [dataSource refresh];
    }
    
    self.uploadingView.queue = [WLUploadingQueue queueForEntriesOfClass:[WLCandy class]];
    
    [WLSession setNumberOfLaunches:[WLSession numberOfLaunches] + 1];
    
    [self performSelector:@selector(showIntroductionIfNeeded) withObject:nil afterDelay:0.0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCreateWrapTipIfNeeded) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)setCreateWrapTipHidden:(BOOL)createWrapTipHidden {
    _createWrapTipHidden = createWrapTipHidden;
    if (self.createWrapTipView.hidden != createWrapTipHidden) {
        [self.createWrapTipView fade];
        self.createWrapTipView.hidden = createWrapTipHidden;
    }
}

- (void)hideCreateWrapTip {
    self.createWrapTipHidden = YES;
}

- (void)showCreateWrapTipIfNeeded {
    __weak typeof(self)weakSelf = self;
    runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
        WLUser *user = [WLUser currentUser];
        NSOrderedSet *wraps = user.wraps;
        NSUInteger numberOfLaunches = [WLSession numberOfLaunches];
        
        void (^showBlock)(void) = ^ {
            if (weakSelf.createWrapTipHidden) {
                weakSelf.createWrapTipHidden = NO;
                [weakSelf performSelector:@selector(hideCreateWrapTip) withObject:nil afterDelay:10.0f];
            }
        };
        
        if (numberOfLaunches == 1) {
            if (!self.presentedViewController && wraps.count == 0) {
                showBlock();
            }
        } else if (numberOfLaunches == 2) {
            static BOOL shownForSecondLaunch = NO;
            if (wraps.count == 0 || !shownForSecondLaunch) {
                shownForSecondLaunch = YES;
                showBlock();
            }
        } else if (wraps.count == 0) {
            showBlock();
        }
        [operation finish];
    });
}

- (void)showIntroductionIfNeeded {
    NSUInteger numberOfLaunches = [WLSession numberOfLaunches];
    if (numberOfLaunches == 1) {
        static BOOL introductionShown = NO;
        if (!introductionShown) {
            introductionShown = YES;
            WLIntroductionViewController *introduction = [[UIStoryboard storyboardNamed:WLIntroductionStoryboard] instantiateInitialViewController];
            introduction.delegate = self;
            [self presentViewController:introduction animated:NO completion:nil];
            return;
        }
    }
    
    [self showCreateWrapTipIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    [self.dataSource reload];
    [self updateNotificationsLabel];
    [self updateEmailConfirmationView:NO];
    [WLRemoteEntryHandler sharedHandler].isLoaded = [self isViewLoaded];
    [self.uploadingView update];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self hideCreateWrapTip];
}

- (void)updateEmailConfirmationView:(BOOL)animated {
    BOOL hidden = ([[WLSession confirmationDate] isToday] || ![[WLAuthorization currentAuthorization] unconfirmed_email].nonempty);
    if (!hidden) {
        self.verificationEmailLabel.attributedText = [WLAuthorization attributedVerificationSuggestion];
        [self deadlineEmailConfirmationView];
    }
    [self setEmailConfirmationViewHidden:hidden animated:animated];
}

- (void)setEmailConfirmationViewHidden:(BOOL)hidden animated:(BOOL)animated {
    
    NSArray *constraints = [self.view.constraints copy];
    
    NSLayoutConstraint *visibleConstraint = self.visibleEmailConfirmationConstraint;
    NSLayoutConstraint *hiddenConstraint = self.hiddenEmailConfirmationConstraint;
    
    if (hidden) {
        if ([constraints containsObject:visibleConstraint]) [self.view removeConstraint:visibleConstraint];
        if (![constraints containsObject:hiddenConstraint]) [self.view addConstraint:hiddenConstraint];
    } else {
        if ([constraints containsObject:hiddenConstraint]) [self.view removeConstraint:hiddenConstraint];
        if (![constraints containsObject:visibleConstraint]) [self.view addConstraint:visibleConstraint];
    }
    
    if (![self.view.constraints isEqualToArray:constraints]) {
        __weak typeof(self)weakSelf = self;
        [UIView performAnimated:animated animation:^{
            [weakSelf.view layoutIfNeeded];
        }];
    }
}

- (void)deadlineEmailConfirmationView {
    [WLSession setConfirmationDate:[NSDate now]];
    [self performSelector:@selector(hideConfirmationEmailView) withObject:nil afterDelay:15.0f];
}

- (void)hideConfirmationEmailView {
    [self setEmailConfirmationViewHidden:YES animated:YES];
}

- (void)openCameraAnimated:(BOOL)animated startFromGallery:(BOOL)startFromGallery showWrapPicker:(BOOL)showPicker {
    WLWrap *wrap = self.dataSource.wrap;
    if (wrap) {
        WLStillPictureViewController *stillPictureViewController = [WLStillPictureViewController instantiate:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
        stillPictureViewController.wrap = wrap;
        stillPictureViewController.mode = WLStillPictureModeDefault;
        stillPictureViewController.delegate = self;
        stillPictureViewController.startFromGallery = startFromGallery;
        __weak typeof(self)weakSelf = self;
        [self presentViewController:stillPictureViewController animated:animated completion:^{
            if (showPicker) {
                 [weakSelf stillPictureViewController:stillPictureViewController didSelectWrap:wrap];
            }
        }];
    } else {
        [self createWrap:nil];
    }
}

// MARK: - WLWrapCellDelegate

- (void)wrapCell:(WLWrapCell *)wrapCell didDeleteWrap:(WLWrap *)wrap {
    if (wrap.valid) {
        WLEditWrapViewController *editWrapViewController = [[WLEditWrapViewController alloc] initWithNibName:@"WLWrapOptionsViewController"
                                                                                                      bundle:nil];
        editWrapViewController.wrap = wrap;
        [self presentViewController:editWrapViewController animated:NO completion:nil];
    }
}

- (void)wrapCell:(WLWrapCell *)wrapCell forWrap:(WLWrap *)wrap notifyChatButtonClicked:(id)sender {
    self.chatSegueWrap = wrap;
}

- (void)wrapCell:(WLWrapCell *)wrapCell forWrap:(WLWrap *)wrap presentChatViewController:(id)sender {
    WLChatViewController *chatViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"WLChatViewController"];
    if (chatViewController && wrap.valid) {
        chatViewController.wrap = wrap;
        [self.navigationController pushViewController:chatViewController animated:NO];
    }
}
- (void)wrapCell:(WLWrapCell *)wrapCell forWrap:(WLWrap *)wrap presentCameraViewController:(id)sender {
    if (wrap.valid) {
        self.dataSource.wrap = wrap;
        [self openCameraAnimated:NO startFromGallery:NO showWrapPicker:NO];
    }
}

// MARK: - WLEntryNotifyReceiver

- (void)addNotifyReceivers {
    
    __weak typeof(self)weakSelf = self;
    
    [WLWrap notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setAddedBlock:^(WLWrap *wrap) {
            WLPaginatedSet *wraps = [weakSelf.dataSource items];
            [wraps addEntry:wrap];
            weakSelf.collectionView.contentOffset = CGPointZero;
        }];
        [receiver setUpdatedBlock:^(WLWrap *wrap) {
            WLPaginatedSet *wraps = [weakSelf.dataSource items];
            [wraps resetEntries:[[WLUser currentUser] sortedWraps]];
        }];
        [receiver setDeletedBlock:^(WLWrap *wrap) {
            WLPaginatedSet *wraps = [weakSelf.dataSource items];
            [wraps removeEntry:wrap];
            run_after(.5, ^{
                [weakSelf updateNotificationsLabel];
            });
        }];
    }];
    
    WLEntryNotifyReceiver *candyNotifyReceiver = [WLCandy notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setAddedBlock:^(id object) {
            [weakSelf updateNotificationsLabel];
        }];
        [receiver setDeletedBlock:^(id object) {
            run_after(.5, ^{
                [weakSelf updateNotificationsLabel];
            });
        }];
        [receiver setUpdatedBlock:^(id object) {
            run_after(.5, ^{
                [weakSelf updateNotificationsLabel];
            });
        }];
    }];
    
    [WLComment notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        receiver.addedBlock = candyNotifyReceiver.addedBlock;
        receiver.deletedBlock = candyNotifyReceiver.deletedBlock;
    }];
    
    [WLUser notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setUpdatedBlock:^(WLUser *user) {
            if (weakSelf.isTopViewController) {
                [weakSelf updateEmailConfirmationView:YES];
            }
        }];
    }];
}

// MARK: - WLNotificationReceiver

- (void)updateNotificationsLabel {
    self.notificationsLabel.intValue = [[WLUser currentUser] unreadNotificationsCount];
}

// MARK: - Actions

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
        if (wrap.isFirstCreated) {
            [WLChronologicalEntryPresenter presentEntry:wrap animated:NO];
        }
        stillPictureViewController.wrap = wrap;
        [stillPictureViewController dismissViewControllerAnimated:NO completion:NULL];
    }];
    
    [createWrapViewController setCancelHandler:^{
        [weakSelf dismissViewControllerAnimated:NO completion:NULL];
    }];
    
    [self presentViewController:stillPictureViewController animated:NO completion:^{
        [stillPictureViewController presentViewController:createWrapViewController animated:NO completion:nil];
    }];
}

- (IBAction)addPhoto:(id)sender {
    [self openCameraAnimated:NO startFromGallery:NO showWrapPicker:YES];
}

// MARK: - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    WLWrap* wrap = controller.wrap;
    if (wrap) {
        [wrap uploadPictures:pictures];
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didSelectWrap:(WLWrap *)wrap {
    if (wrap) {
        WLPickerViewController *pickerViewController = [[WLPickerViewController alloc] initWithWrap:wrap delegate:self];
        [controller presentViewController:pickerViewController animated:NO completion:nil];
    } else {
        [self createWrapWithStillPictureViewController:controller];
    }
}

// MARK: - WLPickerViewDelegate

- (void)createWrapWithStillPictureViewController:(WLStillPictureViewController*)stillPictureViewController {
    WLCreateWrapViewController *createWrapViewController = [WLCreateWrapViewController new];
    [createWrapViewController setCreateHandler:^(WLWrap *wrap) {
        if (wrap.isFirstCreated) {
            [WLChronologicalEntryPresenter presentEntry:wrap animated:NO];
        }
        stillPictureViewController.wrap = wrap;
        [stillPictureViewController dismissViewControllerAnimated:NO completion:NULL];
    }];
    [createWrapViewController setCancelHandler:^{
        [stillPictureViewController dismissViewControllerAnimated:NO completion:NULL];
    }];
    [stillPictureViewController presentViewController:createWrapViewController animated:NO completion:nil];
}

- (void)pickerViewControllerNewWrapClicked:(WLPickerViewController *)pickerViewController {
    WLStillPictureViewController* stillPictureViewController = (id)pickerViewController.presentingViewController;
    __weak typeof(self)weakSelf = self;
    [stillPictureViewController dismissViewControllerAnimated:NO completion:^{
        [weakSelf createWrapWithStillPictureViewController:stillPictureViewController];
    }];
}

- (void)pickerViewController:(WLPickerViewController *)pickerViewController didSelectWrap:(WLWrap *)wrap {
    WLStillPictureViewController* stillPictureViewController = (id)pickerViewController.presentingViewController;
    stillPictureViewController.wrap = wrap;
}

- (void)pickerViewControllerDidCancel:(WLPickerViewController *)pickerViewController {
    [pickerViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

// MARK: - WLIntroductionViewControllerDelegate

- (void)introductionViewControllerDidFinish:(WLIntroductionViewController *)controller {
    __weak typeof(self)weakSelf = self;
    [self dismissViewControllerAnimated:NO completion:^{
        [weakSelf showCreateWrapTipIfNeeded];
    }];
}

// MARK: - WLTouchViewDelegate

- (void)touchViewDidReceiveTouch:(WLTouchView *)touchView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideCreateWrapTip) object:nil];
    [self hideCreateWrapTip];
}

- (NSSet *)touchViewExclusionRects:(WLTouchView *)touchView {
    return [NSSet setWithObject:[NSValue valueWithCGRect:[touchView convertRect:self.createWrapButton.bounds fromView:self.createWrapButton]]];
}

@end
