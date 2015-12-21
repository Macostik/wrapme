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
#import "WLAddressBook.h"
#import "WLTouchView.h"
#import "WLHistoryViewController.h"
#import "WLHintView.h"
#import "WLUploadingQueue.h"
#import "WLChangeProfileViewController.h"
#import "WLStillPictureViewController.h"

@interface WLHomeViewController () <WrapCellDelegate, WLTouchViewDelegate, RecentUpdateListNotifying, WLStillPictureViewControllerDelegate>

@property (strong, nonatomic) IBOutlet SegmentedStreamDataSource *dataSource;

@property (strong, nonatomic) IBOutlet PaginatedStreamDataSource *publicDataSource;

@property (strong, nonatomic) IBOutlet HomeDataSource *homeDataSource;
@property (weak, nonatomic) IBOutlet StreamView *streamView;
@property (weak, nonatomic) IBOutlet UIView *emailConfirmationView;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *notificationsLabel;
@property (weak, nonatomic) IBOutlet WLUploadingView *uploadingView;
@property (weak, nonatomic) IBOutlet UIView *createWrapTipView;
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
    [[WLAddressBook sharedAddressBook] endCaching];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewDidLoad {
    __weak StreamView *streamView = self.streamView;
    
    __weak HomeDataSource *homeDataSource = self.homeDataSource;
    __weak PaginatedStreamDataSource *publicDataSource = self.publicDataSource;
    
    streamView.contentInset = streamView.scrollIndicatorInsets;
    
    __weak typeof(self)weakSelf = self;
    
    [homeDataSource.autogeneratedMetrics change:^(StreamMetrics *metrics) {
        [metrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
            return position.index == 0 ? 70 : 60;
        }];
        
        [metrics setInsetsAt:^CGRect(StreamPosition *position, StreamMetrics *metrics) {
            return CGRectMake(0, position.index == 1 ? 5 : 0, 0, 0);
        }];
        
        publicDataSource.autogeneratedMetrics.selection = metrics.selection = ^(StreamItem *item, id entry) {
            [ChronologicalEntryPresenter presentEntry:entry animated:NO];
        };
        
        [publicDataSource.autogeneratedMetrics setInsetsAt:^CGRect(StreamPosition *position, StreamMetrics *metrics) {
            return CGRectMake(0, position.index == 0 ? 5 : 0, 0, 0);
        }];
    }];
    
    [homeDataSource addMetrics:[[StreamMetrics alloc] initWithIdentifier:@"RecentCandiesView" initializer:^(StreamMetrics *metrics) {
        [metrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
            int size = (streamView.width - 2.0f)/3.0f;
            return ([homeDataSource.wrap.candies count] > [Constants recentCandiesLimit_2] ? 2*size : size) + 5;
        }];
        [metrics setFinalizeAppearing:^(StreamItem *item, id entry) {
            weakSelf.candiesView = (id)item.view;
            [weakSelf finalizeAppearingOfCandiesView:weakSelf.candiesView];
        }];
        [metrics setHiddenAt:^BOOL(StreamPosition *position, StreamMetrics *metrics) {
            return position.index != 0;
        }];
    }]];
    
    [publicDataSource.loadingMetrics setSizeAt:^CGFloat(StreamPosition * position, StreamMetrics * metrics) {
        return streamView.height - weakSelf.publicWrapsHeaderView.height - 48;
    }];
    
    [self.dataSource setRefreshableWithStyle:RefresherStyleOrange];
    
    [super viewDidLoad];
    
    self.createWrapTipHidden = YES;
    
    [[WLAddressBook sharedAddressBook] beginCaching];
    
    [self addNotifyReceivers];
    
    NSSet* wraps = [User currentUser].wraps;
    
    homeDataSource.items = [[PaginatedList alloc] initWithEntries:wraps.allObjects request:[PaginatedRequest wraps:nil]];
    
    if (wraps.nonempty) {
        [homeDataSource refresh];
    }
    
    self.uploadingView.queue = [WLUploadingQueue defaultQueueForEntityName:[Candy entityName]];
    
    [NSUserDefaults standardUserDefaults].numberOfLaunches++;
    
    [self performSelector:@selector(showCreateWrapTipIfNeeded) withObject:nil afterDelay:0.0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCreateWrapTipIfNeeded) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[RecentUpdateList sharedList] addReceiver:self];
    
    [self fetchLiveBroadcasts];
}

- (void)fetchLiveBroadcasts {
    __weak typeof(self)weakSelf = self;
    [[PubNub sharedInstance] hereNowForChannelGroup:[WLNotificationCenter defaultCenter].userSubscription.name withCompletion:^(PNPresenceChannelGroupHereNowResult *result, PNErrorStatus *status) {
        NSDictionary *channels = result.data.channels;
        for (NSString *channel in channels) {
            Wrap *wrap = [Wrap entry:channel];
            if (wrap == nil) {
                continue;
            }
            NSArray *uuids = channels[channel][@"uuids"];
            NSMutableArray *wrapBroadcasts = [NSMutableArray array];
            for (NSDictionary *uuid in uuids) {
                NSDictionary *state = uuid[@"state"];
                User *user = [User entry:state[@"userUid"]];
                if (user == nil) {
                    continue;
                }
                NSString *viewURL = state[@"viewURL"];
                if (viewURL != nil) {
                    LiveBroadcast *broadcast = [[LiveBroadcast alloc] init];
                    broadcast.broadcaster = user;
                    broadcast.wrap = wrap;
                    broadcast.title = state[@"title"];
                    broadcast.channel = state[@"chatChannel"];
                    broadcast.url = viewURL;
                    [wrapBroadcasts addObject:broadcast];
                }
                [user fetchIfNeeded:nil failure:nil];
            }
            wrap.liveBroadcasts = [wrapBroadcasts copy];
            [wrap fetchIfNeeded:nil failure:nil];
        }
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

- (void)setCreateWrapTipHidden:(BOOL)createWrapTipHidden {
    _createWrapTipHidden = createWrapTipHidden;
    if (self.createWrapTipView.hidden != createWrapTipHidden) {
        [self.createWrapTipView addAnimation:[CATransition transition:kCATransitionFade]];
        self.createWrapTipView.hidden = createWrapTipHidden;
    }
}

- (void)hideCreateWrapTip {
    self.createWrapTipHidden = YES;
}

- (void)showCreateWrapTipIfNeeded {
    __weak typeof(self)weakSelf = self;
    [[RunQueue fetchQueue] run:^(Block finish) {
        User *user = [User currentUser];
        NSSet *wraps = user.wraps;
        NSUInteger numberOfLaunches = [[NSUserDefaults standardUserDefaults] numberOfLaunches];
        
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
        finish();
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
    [self hideCreateWrapTip];
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

// MARK: - WLTouchViewDelegate

- (void)touchViewDidReceiveTouch:(WLTouchView *)touchView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideCreateWrapTip) object:nil];
    [self hideCreateWrapTip];
}

- (NSSet *)touchViewExclusionRects:(WLTouchView *)touchView {
    return [NSSet setWithObject:[NSValue valueWithCGRect:[touchView convertRect:self.createWrapButton.bounds fromView:self.createWrapButton]]];
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
