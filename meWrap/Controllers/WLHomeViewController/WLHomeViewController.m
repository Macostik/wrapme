//
//  WLHomeViewController.m
//  meWrap
//
//  Created by Ravenpod on 19.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLOperationQueue.h"
#import "UIFont+CustomFonts.h"
#import "UIView+AnimationHelper.h"
#import "WLCandyViewController.h"
#import "WLHomeDataSource.h"
#import "WLHomeViewController.h"
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
#import "WLGradientView.h"
#import "WLCandyCell.h"
#import "WLPresentingImageView.h"
#import "WLHistoryViewController.h"
#import "WLWhatsUpSet.h"
#import "SegmentedControl.h"
#import "WLNavigationHelper.h"
#import "WLHintView.h"
#import "WLLayoutPrioritizer.h"
#import "WLMessagesCounter.h"
#import "SegmentedStreamDataSource.h"
#import "WLUploadingQueue.h"
#import "WLEntry+WLUploadingQueue.h"
#import "WLFollowingViewController.h"
#import "WLSoundPlayer.h"

@interface WLHomeViewController () <WLWrapCellDelegate, WLIntroductionViewControllerDelegate, WLTouchViewDelegate, WLPresentingImageViewDelegate, WLWhatsUpSetBroadcastReceiver, WLMessagesCounterReceiver>

@property (strong, nonatomic) IBOutlet SegmentedStreamDataSource *dataSource;

@property (strong, nonatomic) IBOutlet PaginatedStreamDataSource *publicDataSource;

@property (strong, nonatomic) IBOutlet WLHomeDataSource *homeDataSource;
@property (weak, nonatomic) IBOutlet StreamView *streamView;
@property (weak, nonatomic) IBOutlet UIView *emailConfirmationView;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *notificationsLabel;
@property (weak, nonatomic) IBOutlet WLUploadingView *uploadingView;
@property (weak, nonatomic) IBOutlet UIView *createWrapTipView;
@property (weak, nonatomic) IBOutlet UIButton *createWrapButton;
@property (weak, nonatomic) IBOutlet WLLabel *verificationEmailLabel;
@property (strong, nonatomic) IBOutlet WLLayoutPrioritizer *emailConfirmationLayoutPrioritizer;
@property (weak, nonatomic) IBOutlet UIButton *photoButton;

@property (weak, nonatomic) WLRecentCandiesView *candiesView;

@property (nonatomic) BOOL createWrapTipHidden;

@end

@implementation WLHomeViewController

- (void)dealloc {
    [[WLAddressBook addressBook] endCaching];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewDidLoad {
    StreamView *streamView = self.streamView;
    
    __weak WLHomeDataSource *homeDataSource = self.homeDataSource;
    __weak PaginatedStreamDataSource *publicDataSource = self.publicDataSource;
    
    streamView.contentInset = streamView.scrollIndicatorInsets;
    
    __weak typeof(self)weakSelf = self;
    
    [[homeDataSource.metrics lastObject] change:^(StreamMetrics *metrics) {
        [metrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
            return position.index == 0 ? 70 : 60;
        }];
        
        [metrics setInsetsAt:^CGRect(StreamPosition *position, StreamMetrics *metrics) {
            return CGRectMake(0, position.index == 1 ? 5 : 0, 0, 0);
        }];
        
        metrics.selection = ^(StreamItem *item, id entry) {
            [WLChronologicalEntryPresenter presentEntry:entry animated:NO];
        };
    }];
    
    [homeDataSource addMetrics:[[StreamMetrics alloc] initWithInitializer:^(StreamMetrics *metrics) {
        metrics.identifier = @"WLRecentCandiesView";
        [metrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
            int size = (streamView.width - 2.0f)/3.0f;;
            return ([weakSelf.homeDataSource.wrap.candies count] > WLHomeTopWrapCandiesLimit_2 ? 2*size : size) + 5;
        }];
        [metrics setFinalizeAppearing:^(StreamItem *item, id entry) {
            weakSelf.candiesView = (id)item.view;
            [weakSelf finalizeAppearingOfCandiesView:weakSelf.candiesView];
        }];
        [metrics setHiddenAt:^BOOL(StreamPosition *position, StreamMetrics *metrics) {
            return position.index != 0;
        }];
    }]];
    
    [[publicDataSource.metrics lastObject] change:^(StreamMetrics *metrics) {
        [metrics setInsetsAt:^CGRect(StreamPosition *position, StreamMetrics *metrics) {
            return CGRectMake(0, position.index == 0 ? 5 : 0, 0, 0);
        }];
        metrics.selection = ^(StreamItem *item, id entry) {
            [WLChronologicalEntryPresenter presentEntry:entry animated:NO];
        };
    }];
    
    [self.dataSource setRefreshable];
    
    [super viewDidLoad];
    
    self.createWrapTipHidden = YES;
    
    [[WLAddressBook addressBook] beginCaching];
    
    [self addNotifyReceivers];
    
    NSSet* wraps = [WLUser currentUser].wraps;
    homeDataSource.items = [WLPaginatedSet setWithEntries:wraps request:[WLPaginatedRequest wraps:nil]];
    publicDataSource.items = [WLPaginatedSet setWithEntries:[[WLWrap entriesWhere:@"isPublic == YES"] set] request:[WLPaginatedRequest wraps:@"public"]];
    
    if (wraps.nonempty) {
        [homeDataSource refresh];
    }
    
    self.uploadingView.queue = [WLUploadingQueue queueForEntriesOfClass:[WLCandy class]];
    
    WLSession.numberOfLaunches++;
    
    [self performSelector:@selector(showIntroductionIfNeeded) withObject:nil afterDelay:0.0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCreateWrapTipIfNeeded) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[WLWhatsUpSet sharedSet].broadcaster addReceiver:self];
    
    [[WLMessagesCounter instance] addReceiver:self];
}

- (void)finalizeAppearingOfCandiesView:(WLRecentCandiesView*)candiesView {
    __weak typeof(self)weakSelf = self;
    StreamMetrics *metrics = [candiesView.dataSource.metrics firstObject];
    [metrics setSelection:^(StreamItem *candyItem, WLCandy *candy) {
        WLCandyCell *cell = (id)candyItem.view;
        
        if (!candy) {
            [weakSelf addPhoto:nil];
            return;
        }
        
        if (candy.valid && cell.coverView.image != nil) {
            WLHistoryViewController *historyViewController = (id)[candy viewController];
            if (historyViewController) {
                WLPresentingImageView *presentingImageView = [WLPresentingImageView sharedPresenting];
                presentingImageView.delegate = weakSelf;
                historyViewController.presentingImageView = presentingImageView;
                [presentingImageView presentCandy:candy fromView:candyItem.view success:^(WLPresentingImageView *presetingImageView) {
                    [weakSelf.navigationController pushViewController:historyViewController animated:NO];
                } failure:^(NSError *error) {
                    [WLChronologicalEntryPresenter presentEntry:candy animated:YES];
                }];
            }
        } else {
            [WLChronologicalEntryPresenter presentEntry:candy animated:YES];
        }
    }];
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
    if (WLSession.numberOfLaunches == 1) {
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
    if (WLSession.numberOfLaunches >= 3 && [WLUser currentUser].wraps.count >= 3) {
        [WLHintView showHomeSwipeTransitionHintViewInView:[UIWindow mainWindow]];
    }
    [self.streamView unlock];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self hideCreateWrapTip];
    [self.streamView lock];
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
    WLWrap *wrap = nil;
    if (self.dataSource.currentDataSource == self.publicDataSource) {
        for (WLWrap *_wrap in [(WLPaginatedSet *)[self.publicDataSource items] entries]) {
            if (_wrap.isContributing) {
                wrap = _wrap;
                break;
            }
        }
    }
    if (!wrap) {
        wrap = self.homeDataSource.wrap;
    }
    [self openCameraForWrap:wrap animated:animated startFromGallery:startFromGallery showWrapPicker:showPicker];
}

- (void)openCameraForWrap:(WLWrap*)wrap animated:(BOOL)animated startFromGallery:(BOOL)startFromGallery showWrapPicker:(BOOL)showPicker {
    if (wrap) {
        WLStillPictureViewController *stillPictureViewController = [WLStillPictureViewController stillPhotosViewController];
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
    [self.streamView lock];
}

- (void)wrapCellDidEndPanning:(WLWrapCell *)wrapCell performedAction:(BOOL)performedAction {
    [self.streamView unlock];
    self.streamView.userInteractionEnabled = !performedAction;
}

- (void)wrapCell:(WLWrapCell *)wrapCell presentChatViewControllerForWrap:(WLWrap *)wrap {
    self.streamView.userInteractionEnabled = YES;
    WLWrapViewController *wrapViewController = [WLWrapViewController instantiate:self.storyboard];
    if (wrapViewController && wrap.valid) {
        wrapViewController.wrap = wrap;
        wrapViewController.segment = WLWrapSegmentChat;
        [self.navigationController pushViewController:wrapViewController animated:YES];
    }
}
- (void)wrapCell:(WLWrapCell *)wrapCell presentCameraViewControllerForWrap:(WLWrap *)wrap {
    self.streamView.userInteractionEnabled = YES;
    if (wrap.valid) {
        [self openCameraForWrap:wrap animated:YES startFromGallery:NO showWrapPicker:NO];
    }
}

// MARK: - WLEntryNotifyReceiver

- (void)addNotifyReceivers {
    
    __weak typeof(self)weakSelf = self;
    
    [WLWrap notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setDidAddBlock:^(WLWrap *wrap) {
            if (wrap.isPublic) {
                [weakSelf.publicDataSource.items sort:wrap];
            }
            if (wrap.isContributing) {
                [weakSelf.homeDataSource.items sort:wrap];
            }
            weakSelf.streamView.contentOffset = CGPointZero;
        }];
        [receiver setDidUpdateBlock:^(WLWrap *wrap) {
            if (wrap.isPublic) {
                [weakSelf.publicDataSource.items sort:wrap];
            }
            if (wrap.isContributing) {
                [weakSelf.homeDataSource.items sort:wrap];
            } else {
                [weakSelf.homeDataSource.items removeEntry:wrap];
            }
        }];
        [receiver setWillDeleteBlock:^(WLWrap *wrap) {
            if (wrap.isPublic) {
                [weakSelf.publicDataSource.items removeEntry:wrap];
            }
            if (wrap.isContributing) {
                [weakSelf.homeDataSource.items removeEntry:wrap];
            }
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
    [[WLAPIRequest resendConfirmation:nil] send:^(id object) {
        [WLToast showWithMessage:WLLS(@"confirmation_resend")];
    } failure:^(NSError *error) {
    }];
}

- (IBAction)createWrap:(id)sender {
    WLStillPictureViewController *controller = [WLStillPictureViewController stillPhotosViewController];
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
        [self dismissViewControllerAnimated:NO completion:nil];
        [WLFollowingViewController followWrapIfNeeded:wrap performAction:^{
            [WLSoundPlayer playSound:WLSound_s04];
            [wrap uploadPictures:pictures];
        }];
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

// MARK: - WLPresentingImageViewDelegate

- (UIView *)presentingImageView:(WLPresentingImageView *)presentingImageView dismissingViewForCandy:(WLCandy *)candy {
    [self.streamView scrollRectToVisible:self.candiesView.frame animated:NO];
    return [[self.candiesView.streamView itemPassingTest:^BOOL(StreamItem *item) {
        return item.entry == candy;
    }] view];
}

// MARK: - WLWhatsUpSetBroadcastReceiver

- (void)whatsUpBroadcaster:(WLBroadcaster *)broadcaster updated:(WLWhatsUpSet *)set {
    for (StreamItem *item in self.streamView.visibleItems) {
        if ([item.view isKindOfClass:[WLWrapCell class]]) {
            [(WLWrapCell*)item.view updateCandyNotifyCounter];
        }
    }
    self.notificationsLabel.intValue = set.unreadEntriesCount;
}

// MARK: - WLMessagesCounterReceiver

- (void)counterDidChange:(WLMessagesCounter *)counter {
    for (StreamItem *item in self.streamView.visibleItems) {
        if ([item.view isKindOfClass:[WLWrapCell class]]) {
            [(WLWrapCell*)item.view updateChatNotifyCounter];
        }
    }
}

@end
