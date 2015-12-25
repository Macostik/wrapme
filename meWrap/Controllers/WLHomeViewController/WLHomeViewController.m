//
//  WLHomeViewController.m
//  meWrap
//
//  Created by Ravenpod on 19.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandyViewController.h"
#import "WLHomeViewController.h"
#import "WLBadgeLabel.h"
#import "WLToast.h"
#import "WLWrapViewController.h"
#import "WLUploadingView.h"
#import "WLHistoryViewController.h"
#import "WLHintView.h"
#import "WLUploadingQueue.h"
#import "WLChangeProfileViewController.h"
#import "WLStillPictureViewController.h"

@interface WLHomeViewController () <WrapCellDelegate, RecentUpdateListNotifying, WLStillPictureViewControllerDelegate>

@property (strong, nonatomic) IBOutlet SegmentedStreamDataSource *dataSource;

@property (strong, nonatomic) IBOutlet PaginatedStreamDataSource *publicDataSource;

@property (strong, nonatomic) IBOutlet HomeDataSource *homeDataSource;
@property (weak, nonatomic) IBOutlet StreamView *streamView;
@property (weak, nonatomic) IBOutlet UIView *emailConfirmationView;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *notificationsLabel;
@property (weak, nonatomic) IBOutlet WLUploadingView *uploadingView;
@property (weak, nonatomic) IBOutlet UIButton *createWrapButton;
@property (weak, nonatomic) IBOutlet WLLabel *verificationEmailLabel;
@property (strong, nonatomic) IBOutlet LayoutPrioritizer *emailConfirmationLayoutPrioritizer;
@property (weak, nonatomic) IBOutlet UIButton *photoButton;
@property (weak, nonatomic) RecentCandiesView *candiesView;

@property (nonatomic) BOOL createWrapTipHidden;
@property (weak, nonatomic) IBOutlet UIView *publicWrapsHeaderView;

@end

@implementation WLHomeViewController

- (void)dealloc {
    [[AddressBook sharedAddressBook] endCaching];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewDidLoad {
    __weak StreamView *streamView = self.streamView;
    
    __weak HomeDataSource *homeDataSource = self.homeDataSource;
    __weak PaginatedStreamDataSource *publicDataSource = self.publicDataSource;
    
    streamView.contentInset = streamView.scrollIndicatorInsets;
    
    __weak typeof(self)weakSelf = self;
    
    UIViewController *firstStep = [UIStoryboard introduction][@"newlySignupScreen"];
    [self presentViewController:firstStep animated:NO completion:nil];
    
    [homeDataSource.autogeneratedMetrics change:^(StreamMetrics *metrics) {
        [metrics setSizeAt:^CGFloat(StreamItem *item) {
            return item.position.index == 0 ? 70 : 60;
        }];
        
        [metrics setInsetsAt:^CGRect(StreamItem *item) {
            return CGRectMake(0, item.position.index == 1 ? 5 : 0, 0, 0);
        }];
        
        publicDataSource.autogeneratedMetrics.selection = metrics.selection = ^(StreamItem *item, id entry) {
            [ChronologicalEntryPresenter presentEntry:entry animated:NO];
        };
        
        [publicDataSource.autogeneratedMetrics setInsetsAt:^CGRect(StreamItem *item) {
            return CGRectMake(0, item.position.index == 0 ? 5 : 0, 0, 0);
        }];
    }];
    
    [homeDataSource addMetrics:[[StreamMetrics alloc] initWithIdentifier:@"RecentCandiesView" initializer:^(StreamMetrics *metrics) {
        [metrics setSizeAt:^CGFloat(StreamItem *item) {
            int size = (streamView.width - 2.0f)/3.0f;
            return ([homeDataSource.wrap.candies count] > [Constants recentCandiesLimit_2] ? 2*size : size) + 5;
        }];
        [metrics setFinalizeAppearing:^(StreamItem *item, StreamReusableView *view) {
            weakSelf.candiesView = (id)view;
            [weakSelf finalizeAppearingOfCandiesView:weakSelf.candiesView];
        }];
        [metrics setHiddenAt:^BOOL(StreamItem *item) {
            return item.position.index != 0;
        }];
    }]];
    
    [publicDataSource.loadingMetrics setSizeAt:^CGFloat(StreamItem *item) {
        return streamView.height - weakSelf.publicWrapsHeaderView.height - 48;
    }];
    
    [self.dataSource setRefreshableWithStyle:RefresherStyleOrange];
    
    [super viewDidLoad];
    
    self.createWrapTipHidden = YES;
    
    [[AddressBook sharedAddressBook] beginCaching];
    
    [self addNotifyReceivers];
    
    NSSet* wraps = [User currentUser].wraps;
    
    homeDataSource.items = [[PaginatedList alloc] initWithEntries:wraps.allObjects request:[PaginatedRequest wraps:nil]];
    
    if (wraps.nonempty) {
        [homeDataSource refresh];
    }
    
    self.uploadingView.queue = [WLUploadingQueue defaultQueueForEntityName:[Candy entityName]];
    
    [NSUserDefaults standardUserDefaults].numberOfLaunches++;
    
    [[RecentUpdateList sharedList] addReceiver:self];
    
    [[WLNotificationCenter defaultCenter] fetchLiveBroadcasts:^{
        [weakSelf.dataSource reload];
    }];
}

- (void)finalizeAppearingOfCandiesView:(RecentCandiesView*)candiesView {
    __weak typeof(self)weakSelf = self;
    StreamMetrics *metrics = [candiesView.dataSource.metrics firstObject];
    [metrics setSelection:^(StreamItem *candyItem, Candy *candy) {
        if (candy) {
            [CandyEnlargingPresenter handleCandySelection:candyItem entry:candy dismissingView:^UIView * _Nullable(CandyEnlargingPresenter *presenter, Candy *candy) {
                [weakSelf.streamView scrollRectToVisible:candiesView.frame animated:NO];
                return [[candiesView.streamView itemPassingTest:^BOOL(StreamItem *item) {
                    return item.entry == candy;
                }] view];
            }];
        } else {
            [weakSelf addPhoto:nil];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    [self.dataSource reload];
    __weak typeof(self)weakSelf = self;
    self.notificationsLabel.value = [RecentUpdateList sharedList].unreadCount;
    [[RecentUpdateList sharedList] refreshCount:^(NSInteger count) {
        weakSelf.notificationsLabel.value = count;
        [weakSelf.dataSource reload];
    } failure:nil];
    
    [self updateEmailConfirmationView:NO];
    [EventualEntryPresenter sharedPresenter].isLoaded = YES;
    [self.uploadingView update];
    if ([NSUserDefaults standardUserDefaults].numberOfLaunches >= 3 && [User currentUser].wraps.count >= 3) {
        [WLHintView showHomeSwipeTransitionHintViewInView:[UIWindow mainWindow]];
    }
    [self.streamView unlock];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.streamView lock];
}

- (void)updateEmailConfirmationView:(BOOL)animated {
    BOOL hidden = ([[[NSUserDefaults standardUserDefaults] confirmationDate] isToday] || ![[Authorization currentAuthorization] unconfirmed_email].nonempty);
    if (!hidden) {
        self.verificationEmailLabel.attributedText = [WLChangeProfileViewController verificationSuggestion];
        [self deadlineEmailConfirmationView];
    }
    [self setEmailConfirmationViewHidden:hidden animated:animated];
}

- (void)setEmailConfirmationViewHidden:(BOOL)hidden animated:(BOOL)animated {
    [self.emailConfirmationLayoutPrioritizer setDefaultState:!hidden animated:animated];
}

- (void)deadlineEmailConfirmationView {
    [[NSUserDefaults standardUserDefaults] setConfirmationDate:[NSDate now]];
    [self performSelector:@selector(hideConfirmationEmailView) withObject:nil afterDelay:15.0f];
}

- (void)hideConfirmationEmailView {
    [self setEmailConfirmationViewHidden:YES animated:YES];
}

// MARK: - WLWrapCellDelegate

- (void)wrapCellDidBeginPanning:(WrapCell *)cell {
    [self.streamView lock];
}

- (void)wrapCellDidEndPanning:(WrapCell *)cell performedAction:(BOOL)performedAction {
    [self.streamView unlock];
    self.streamView.userInteractionEnabled = !performedAction;
}

- (void)wrapCell:(WrapCell *)cell presentChatViewControllerForWrap:(Wrap *)wrap {
    self.streamView.userInteractionEnabled = YES;
    WLWrapViewController *wrapViewController = self.storyboard[@"WLWrapViewController"];
    if (wrapViewController && wrap.valid) {
        wrapViewController.wrap = wrap;
        wrapViewController.segment = WLWrapSegmentChat;
        [self.navigationController pushViewController:wrapViewController animated:YES];
    }
}
- (void)wrapCell:(WrapCell *)cell presentCameraViewControllerForWrap:(Wrap *)wrap {
    self.streamView.userInteractionEnabled = YES;
    if (wrap.valid) {
        [self openCameraForWrap:wrap animated:YES];
    }
}

// MARK: - EntryNotifying

- (void)addNotifyReceivers {
    
    __weak typeof(self)weakSelf = self;
    
    [[Wrap notifyReceiver:self] setup:^(EntryNotifyReceiver *receiver) {
        [receiver setDidAdd:^(Entry *entry) {
            Wrap *wrap = (Wrap*)entry;
            if (wrap.isPublic) {
                [weakSelf.publicDataSource.paginatedSet sort:wrap];
            }
            if (wrap.isContributing) {
                [weakSelf.homeDataSource.paginatedSet sort:wrap];
            }
            weakSelf.streamView.contentOffset = CGPointZero;
        }];
        [receiver setDidUpdate:^(Entry *entry, EntryUpdateEvent event) {
            if (event == EntryUpdateEventNumberOfUnreadMessagesChanged) {
                for (StreamItem *item in weakSelf.streamView.visibleItems) {
                    if ([item.view isKindOfClass:[WrapCell class]]) {
                        [(WrapCell*)item.view updateChatNotifyCounter];
                    }
                }
            } else {
                Wrap *wrap = (Wrap*)entry;
                if (wrap.isPublic) {
                    [weakSelf.publicDataSource.paginatedSet sort:wrap];
                }
                if (wrap.isContributing) {
                    [weakSelf.homeDataSource.paginatedSet sort:wrap];
                } else {
                    [weakSelf.homeDataSource.paginatedSet remove:wrap];
                }
            }
        }];
        [receiver setWillDelete:^(Entry *entry) {
            Wrap *wrap = (Wrap*)entry;
            if (wrap.isPublic) {
                [weakSelf.publicDataSource.paginatedSet remove:wrap];
            }
            if (wrap.isContributing) {
                [weakSelf.homeDataSource.paginatedSet remove:wrap];
            }
        }];
    }];
    
    [[User notifyReceiver:self] setup:^(EntryNotifyReceiver *receiver) {
        [receiver setDidUpdate:^(Entry *entry, EntryUpdateEvent event) {
            if (weakSelf.isTopViewController) {
                [weakSelf updateEmailConfirmationView:YES];
            }
        }];
    }];
}

// MARK: - Actions

- (IBAction)resendConfirmation:(id)sender {
    [[APIRequest resendConfirmation:nil] send:^(id object) {
        [WLToast showWithMessage:@"confirmation_resend".ls];
    } failure:^(NSError *error) {
        [error show];
    }];
}

- (void)openCameraForWrap:(Wrap *)wrap animated:(BOOL)animated {
    WLStillPictureViewController *stillPictureViewController = [WLStillPictureViewController stillPhotosViewController];
    stillPictureViewController.wrap = wrap;
    stillPictureViewController.mode = StillPictureModeDefault;
    stillPictureViewController.delegate = self;
    [self presentViewController:stillPictureViewController animated:animated completion:nil];
}

- (IBAction)createWrap:(id)sender {
    [self openCameraForWrap:nil animated:NO];
}

- (Wrap*)topWrap {
    if (self.dataSource.currentDataSource == self.publicDataSource) {
        for (Wrap *wrap in [(PaginatedList *)[self.publicDataSource items] entries]) {
            if (wrap.isContributing) {
                return wrap;
            }
        }
    }
    return self.homeDataSource.wrap;
}

- (IBAction)addPhoto:(id)sender {
    [self openCameraForWrap:[self topWrap] animated:NO];
}

- (IBAction)hottestWrapsOpened:(id)sender {
    self.publicWrapsHeaderView.hidden = NO;
    NSArray *wraps = nil;
    if (![Network sharedNetwork].reachable) {
        wraps = [[[Wrap fetch] queryString:@"isPublic == YES"] execute];
    }
    self.publicDataSource.items = [[PaginatedList alloc] initWithEntries:wraps request:[PaginatedRequest wraps:@"public"]];
}

- (IBAction)privateWrapsOpened:(id)sender {
    self.publicWrapsHeaderView.hidden = YES;
}

// MARK: - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    [self dismissViewControllerAnimated:NO completion:nil];
    Wrap* wrap = controller.wrap;
    if (wrap) {
        WLWrapViewController *controller = (WLWrapViewController*)[wrap viewControllerWithNavigationController:self.navigationController];
        if (controller) {
            controller.segment = WLWrapSegmentMedia;
            self.navigationController.viewControllers = @[self, controller];
        }
        
        [FollowingViewController followWrapIfNeeded:wrap performAction:^{
            [[SoundPlayer player] play:Sounds04];
            [wrap uploadAssets:pictures];
        }];
    }
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
    [self dismissViewControllerAnimated:NO completion:nil];
}

// MARK: - RecentUpdateListNotifying

- (void)recentUpdateListUpdated:(RecentUpdateList *)list {
    for (StreamItem *item in self.streamView.visibleItems) {
        if ([item.view isKindOfClass:[WrapCell class]]) {
            [(WrapCell*)item.view updateCandyNotifyCounter];
        }
    }
    self.notificationsLabel.value = list.unreadCount;
}

@end
