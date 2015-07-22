//
//  WLHomeViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLOperationQueue.h"
#import "UIFont+CustomFonts.h"
#import "UILabel+Additions.h"
#import "UIView+AnimationHelper.h"
#import "WLCandyViewController.h"
#import "WLHomeDataSource.h"
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
#import "WLUploadingView.h"
#import "WLAddressBook.h"
#import "WLIntroductionViewController.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLTouchView.h"
#import "WLChronologicalEntryPresenter.h"
#import "WLCollectionView.h"
#import "WLGradientView.h"
#import "WLCandyCell.h"
#import "WLPresentingImageView.h"
#import "WLHistoryViewController.h"
#import "WLWhatsUpSet.h"
#import "WLSegmentedControl.h"
#import "WLNavigationHelper.h"
#import "WLHintView.h"
#import "WLLayoutPrioritizer.h"
#import "WLMessagesCounter.h"
#import "WLSegmentedDataSource.h"
#import "WLPublicWrapsDataSource.h"

@interface WLHomeViewController () <WLWrapCellDelegate, WLIntroductionViewControllerDelegate, WLTouchViewDelegate, WLPresentingImageViewDelegate, WLWhatsUpSetBroadcastReceiver, WLMessagesCounterReceiver>

@property (strong, nonatomic) IBOutlet WLSegmentedDataSource *dataSource;

@property (strong, nonatomic) IBOutlet WLPublicWrapsDataSource *publicDataSource;

@property (strong, nonatomic) IBOutlet WLHomeDataSource *homeDataSource;
@property (weak, nonatomic) IBOutlet WLCollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *emailConfirmationView;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *notificationsLabel;
@property (weak, nonatomic) IBOutlet WLUploadingView *uploadingView;
@property (weak, nonatomic) IBOutlet UIView *createWrapTipView;
@property (weak, nonatomic) IBOutlet UIButton *createWrapButton;
@property (weak, nonatomic) IBOutlet WLLabel *verificationEmailLabel;
@property (strong, nonatomic) IBOutlet WLLayoutPrioritizer *emailConfirmationLayoutPrioritizer;

@property (nonatomic) BOOL createWrapTipHidden;

@end

@implementation WLHomeViewController

- (void)dealloc {
    [[WLAddressBook addressBook] endCaching];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewDidLoad {
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"WLPublicWrapsHeaderView" bundle:nil] forSupplementaryViewOfKind:@"WLPublicWrapsHeaderView" withReuseIdentifier:@"WLPublicWrapsHeaderView"];
    UICollectionView *collectionView = self.collectionView;
    [self.dataSource setRefreshable];
    WLCollectionViewLayout *layout = [[WLCollectionViewLayout alloc] init];
    layout.sectionHeadingSupplementaryViewKinds = @[];
    collectionView.collectionViewLayout = layout;
    [layout registerItemFooterSupplementaryViewKind:UICollectionElementKindSectionHeader];
    [layout registerItemHeaderSupplementaryViewKind:@"WLPublicWrapsHeaderView"];
    
    [super viewDidLoad];
    
    self.createWrapTipHidden = YES;
    
    [[WLAddressBook addressBook] beginCaching];
    
    self.collectionView.contentInset = self.collectionView.scrollIndicatorInsets;
    
    [self addNotifyReceivers];
    
    __weak WLHomeDataSource *homeDataSource = self.homeDataSource;
    __weak WLPublicWrapsDataSource *publicDataSource = self.publicDataSource;
    
    NSSet* wraps = [WLUser currentUser].wraps;
    homeDataSource.items = [WLPaginatedSet setWithEntries:wraps request:[WLPaginatedRequest wraps:nil]];
    publicDataSource.items = [WLPaginatedSet setWithEntries:nil request:[WLPaginatedRequest wraps:@"public_not_following"]];
    
    homeDataSource.selectionBlock = publicDataSource.selectionBlock = ^(id entry) {
        [WLChronologicalEntryPresenter presentEntry:entry animated:NO];
    };
    
    if (wraps.nonempty) {
        [homeDataSource refresh];
    }
    
    self.uploadingView.queue = [WLUploadingQueue queueForEntriesOfClass:[WLCandy class]];
    
    [WLSession setNumberOfLaunches:[WLSession numberOfLaunches] + 1];
    
    [self performSelector:@selector(showIntroductionIfNeeded) withObject:nil afterDelay:0.0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCreateWrapTipIfNeeded) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[WLWhatsUpSet sharedSet].broadcaster addReceiver:self];
    
    [[WLMessagesCounter instance] addReceiver:self];
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
        NSSet *wraps = user.wraps;
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
    __weak typeof(self)weakSelf = self;
    self.notificationsLabel.intValue = [WLWhatsUpSet sharedSet].unreadEntriesCount;
    [[WLWhatsUpSet sharedSet] refreshCount:^(NSUInteger count) {
        weakSelf.notificationsLabel.intValue = count;
        [weakSelf.dataSource reload];
    } failure:nil];
    [[WLMessagesCounter instance] update:nil];
    
    [self updateEmailConfirmationView:NO];
    [WLRemoteEntryHandler sharedHandler].isLoaded = [self isViewLoaded];
    [self.uploadingView update];
    NSUInteger numberOfLaunches = [WLSession numberOfLaunches];
    if (numberOfLaunches >= 3 && [WLUser currentUser].wraps.count >= 3) {
          [WLHintView showHomeSwipeTransitionHintViewInView:[UIWindow mainWindow]];
    }
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
    [self.emailConfirmationLayoutPrioritizer setDefaultState:!hidden animated:animated];
}

- (void)deadlineEmailConfirmationView {
    [WLSession setConfirmationDate:[NSDate now]];
    [self performSelector:@selector(hideConfirmationEmailView) withObject:nil afterDelay:15.0f];
}

- (void)hideConfirmationEmailView {
    [self setEmailConfirmationViewHidden:YES animated:YES];
}

- (void)openCameraAnimated:(BOOL)animated startFromGallery:(BOOL)startFromGallery showWrapPicker:(BOOL)showPicker {
    [self openCameraForWrap:self.homeDataSource.wrap animated:animated startFromGallery:startFromGallery showWrapPicker:showPicker];
}

- (void)openCameraForWrap:(WLWrap*)wrap animated:(BOOL)animated startFromGallery:(BOOL)startFromGallery showWrapPicker:(BOOL)showPicker {
    if (wrap) {
        WLStillPictureViewController *stillPictureViewController = [WLStillPictureViewController stillPictureViewController];
        stillPictureViewController.wrap = wrap;
        stillPictureViewController.mode = WLStillPictureModeDefault;
        stillPictureViewController.delegate = self;
        stillPictureViewController.startFromGallery = startFromGallery;
        [self presentViewController:stillPictureViewController animated:animated completion:nil];
        if (showPicker) {
            [stillPictureViewController showWrapPickerWithController:NO];
        }
    } else {
        [self createWrap:nil];
    }
}

// MARK: - WLWrapCellDelegate

- (void)wrapCellDidBeginPanning:(WLWrapCell *)wrapCell {
    [self.collectionView lockReloadingData];
}

- (void)wrapCellDidEndPanning:(WLWrapCell *)wrapCell performedAction:(BOOL)performedAction {
    [self.collectionView unlockReloadingData];
    self.collectionView.userInteractionEnabled = !performedAction;
}

- (void)wrapCell:(WLWrapCell *)wrapCell presentChatViewControllerForWrap:(WLWrap *)wrap {
    self.collectionView.userInteractionEnabled = YES;
    WLWrapViewController *wrapViewController = [WLWrapViewController instantiate:self.storyboard];
    if (wrapViewController && wrap.valid) {
        wrapViewController.wrap = wrap;
        wrapViewController.selectedSegment = WLSegmentControlStateChat;
        [self.navigationController pushViewController:wrapViewController animated:YES];
    }
}
- (void)wrapCell:(WLWrapCell *)wrapCell presentCameraViewControllerForWrap:(WLWrap *)wrap {
    self.collectionView.userInteractionEnabled = YES;
    if (wrap.valid) {
        [self openCameraForWrap:wrap animated:YES startFromGallery:NO showWrapPicker:NO];
    }
}

// MARK: - WLEntryNotifyReceiver

- (void)addNotifyReceivers {
    
    __weak typeof(self)weakSelf = self;
    
    [WLWrap notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setDidAddBlock:^(WLWrap *wrap) {
            WLPaginatedSet *wraps = [weakSelf.homeDataSource items];
            [wraps addEntry:wrap];
            weakSelf.collectionView.contentOffset = CGPointZero;
        }];
        [receiver setDidUpdateBlock:^(WLWrap *wrap) {
            WLPaginatedSet *wraps = [weakSelf.homeDataSource items];
            [wraps resetEntries:[[WLUser currentUser] wraps]];
        }];
        [receiver setWillDeleteBlock:^(WLWrap *wrap) {
            WLPaginatedSet *wraps = [weakSelf.homeDataSource items];
            [wraps removeEntry:wrap];
        }];
    }];
    
    [WLUser notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setDidUpdateBlock:^(WLUser *user) {
            if (weakSelf.isTopViewController) {
                [weakSelf updateEmailConfirmationView:YES];
            }
        }];
    }];
}

// MARK: - Actions

- (IBAction)resendConfirmation:(id)sender {
    [[WLResendConfirmationRequest request] send:^(id object) {
        [WLToast showWithMessage:WLLS(@"confirmation_resend")];
    } failure:^(NSError *error) {
    }];
}

- (IBAction)createWrap:(id)sender {
    WLStillPictureViewController *controller = [WLStillPictureViewController stillPictureViewController];
    controller.mode = WLStillPictureModeDefault;
    controller.delegate = self;
    [self presentViewController:controller animated:NO completion:nil];
}

- (IBAction)addPhoto:(id)sender {
    [self openCameraAnimated:NO startFromGallery:NO showWrapPicker:NO];
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

// MARK: - WLCandyCellDelegate

- (void)candyCell:(WLCandyCell *)cell didSelectCandy:(WLCandy *)candy {
     WLHistoryViewController *historyViewController = (id)[candy viewController];
    if (historyViewController) {
        WLPresentingImageView *presentingImageView = [WLPresentingImageView sharedPresenting];
        presentingImageView.delegate = self;
         historyViewController.presentingImageView = presentingImageView;
        __weak __typeof(self)weakSelf = self;
        [presentingImageView presentingCandy:candy completion:^(BOOL flag) {
            [weakSelf.navigationController pushViewController:historyViewController animated:NO];
        }];
    }
}

// MARK: - WLPresentingImageViewDelegate

- (CGRect)presentImageView:(WLPresentingImageView *)presentingImageView getFrameCandyCell:(WLCandy *)candy {
    presentingImageView.hidden = NO;
    WLCandyCell *candyCell = [self presentedCandyCell:candy];
    return [self.view convertRect:candyCell.frame fromView:candyCell.superview];
}

- (CGRect)dismissImageView:(WLPresentingImageView *)presentingImageView getFrameCandyCell:(WLCandy *)candy {
    WLCandyCell *candyCell = [self presentedCandyCell:candy];
    return [self.view convertRect:candyCell.frame fromView:candyCell.superview];
}

- (WLCandyCell *)presentedCandyCell:(WLCandy *)candy {
    [self.collectionView layoutIfNeeded];
    WLRecentCandiesView *candiesView = self.homeDataSource.candiesView;
    NSUInteger index = [(id)candiesView.dataSource.items indexOfObject:candy];
    if (index != NSNotFound && candiesView) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        WLCandyCell *candyCell = (id)[candiesView.collectionView cellForItemAtIndexPath:indexPath];
        if (candyCell) {
            return candyCell;
        }
    }
    return nil;
}

// MARK: - WLWhatsUpSetBroadcastReceiver

- (void)whatsUpBroadcaster:(WLBroadcaster *)broadcaster updated:(WLWhatsUpSet *)set {
    self.notificationsLabel.intValue = set.unreadEntriesCount;
    [self.dataSource reload];
}

// MARK: - WLMessagesCounterReceiver

- (void)counterDidChange:(WLMessagesCounter *)counter {
    [self.dataSource reload];
}

@end
