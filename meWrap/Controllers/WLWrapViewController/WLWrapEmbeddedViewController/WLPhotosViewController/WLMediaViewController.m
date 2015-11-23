//
//  WLMediaViewController.m
//  
//
//  Created by Yura Granchenko on 10/06/15.
//
//

#import "WLCandyViewController.h"
#import "WLComposeBar.h"
#import "WLCandyCell.h"
#import "WLPresentingImageView.h"
#import "WLHistoryViewController.h"
#import "WLMediaViewController.h"
#import "WLUploadingView.h"
#import "WLFollowingViewController.h"
#import "WLWhatsUpSet.h"
#import "WLBadgeLabel.h"
#import "WLUploadingQueue.h"
#import "WLNetwork.h"
#import "WLToast.h"
@import AVKit;

@interface WLMediaViewController () <WLPresentingImageViewDelegate, EntryNotifying>

@property (strong, nonatomic) MediaDataSource *dataSource;
@property (weak, nonatomic) IBOutlet StreamView *streamView;
@property (strong, nonatomic) IBOutlet LayoutPrioritizer *primaryConstraint;
@property (weak, nonatomic) IBOutlet WLUploadingView *uploadingView;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;

@property (strong, nonatomic) WLHistory *history;

@property (weak, nonatomic) StreamMetrics *candyMetrics;

@end

@implementation WLMediaViewController

@dynamic delegate;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    __weak typeof(self)weakSelf = self;
    
    StreamView *streamView = self.streamView;
    streamView.contentInset = streamView.scrollIndicatorInsets;
    streamView.layout = [[SquareGridLayout alloc] initWithHorizontal:NO];
    
    self.dataSource = [[MediaDataSource alloc] initWithStreamView:streamView];
    self.dataSource.numberOfGridColumns = 3;
    self.dataSource.layoutSpacing = Constants.pixelSize;
    
    if (self.wrap.requiresFollowing && [WLNetwork sharedNetwork].reachable) {
        self.wrap.candies = nil;
    }
    
    [self.dataSource setLiveBroadcasts:^NSArray<LiveBroadcast *> * _Nonnull{
        NSArray *broadcasts = [LiveBroadcast broadcastsForWrap:weakSelf.wrap];
        return broadcasts;
    }];
    
    [self.dataSource.liveBroadcastMetrics setSelection:^(StreamItem *item, id entry) {
        LiveBroadcastViewController *liveBroadcastController = weakSelf.storyboard[@"liveBroadcast"];
        liveBroadcastController.wrap = weakSelf.wrap;
        liveBroadcastController.broadcast = entry;
        [weakSelf.navigationController presentViewController:liveBroadcastController animated:NO completion:nil];
    }];
    
    StreamMetrics *dateMetrics = [[StreamMetrics alloc] initWithIdentifier:@"HistoryDateSeparator"];
    dateMetrics.isSeparator = YES;
    dateMetrics.size = 42.0f;
    [dateMetrics setHiddenAt:^BOOL(StreamPosition * _Nonnull position, StreamMetrics * _Nonnull metrics) {
        Candy *candy = [weakSelf.history.entries tryAt:position.index];
        Candy *previousCandy = [weakSelf.history.entries tryAt:position.index - 1];
        if (previousCandy) {
            return [previousCandy.createdAt isSameDay:candy.createdAt];
        } else {
            return NO;
        }
    }];
    [self.dataSource addMetrics:dateMetrics];
    
    StreamMetrics *metrics = [self.dataSource addMetrics:[[StreamMetrics alloc] initWithIdentifier:@"WLCandyCell"]];
    metrics.selection = ^(StreamItem *item, Candy *candy) {
        WLCandyCell *cell = (id)item.view;
        if (candy.valid && cell.coverView.image != nil) {
            WLHistoryViewController *historyViewController = (id)[candy viewController];
            historyViewController.history = weakSelf.history;
            if (historyViewController) {
                WLPresentingImageView *presentingImageView = [WLPresentingImageView sharedPresenting];
                presentingImageView.delegate = weakSelf;
                historyViewController.presentingImageView = presentingImageView;
                [presentingImageView presentCandy:candy fromView:item.view success:^(WLPresentingImageView *presetingImageView) {
                    [weakSelf.navigationController pushViewController:historyViewController animated:NO];
                } failure:^(NSError *error) {
                    [ChronologicalEntryPresenter presentEntry:candy animated:YES];
                }];
            }
        } else {
            [ChronologicalEntryPresenter presentEntry:candy animated:YES];
        }
    };
    self.candyMetrics = metrics;
    
    [self.dataSource setAppendableBlock:^BOOL(PaginatedStreamDataSource *dataSource) {
        return weakSelf.wrap.uploaded;
    }];
    
    self.history = [WLHistory historyWithWrap:self.wrap];
    
    [self.dataSource setRefreshableWithStyle:Refresher.Orange];
    
    [self firstLoadRequest];
    
    self.uploadingView.queue = [WLUploadingQueue queueForEntityName:[Candy entityName]];
    
    [[WLNetwork sharedNetwork] addReceiver:self];
    
    if (self.wrap.candies.nonempty) {
        [self dropDownCollectionView];
    }
    
    [[Wrap notifier] addReceiver:self];
}

- (void)firstLoadRequest {
    if (self.wrap.candies.nonempty) {
        if (self.dataSource.paginatedSet.entries.count > [NSUserDefaults standardUserDefaults].pageSize) {
            [self.dataSource.paginatedSet newer:nil failure:nil];
        } else {
            [self.dataSource.paginatedSet fresh:nil failure:nil];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __weak typeof(self)weakSelf = self;
    if (self.wrap.valid) {
        __block int unreadCandyCounter = 0;
        [self.wrap.candies all:^(Candy *candy) {
            if (candy.valid && candy.unread) {
                unreadCandyCounter++;
                candy.unread = NO;
            }
        }];
        [[WLWhatsUpSet sharedSet] refreshCount:^(NSUInteger count) {
            weakSelf.badge.value = unreadCandyCounter;
        } failure:^(NSError *error) {
        }];
        self.dataSource.items = self.history;
        [self.uploadingView update];
        [self.dataSource.streamView unlock];
    } else {
        run_after(0.5f, ^{
            [weakSelf.navigationController popViewControllerAnimated:NO];
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.dataSource.streamView lock];
}

// MARK: - User Actions

- (IBAction)addPhoto:(id)sender {
    __weak typeof(self)weakSelf = self;
    [WLFollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        if ([weakSelf.delegate respondsToSelector:@selector(mediaViewControllerDidAddPhoto:)]) {
            [weakSelf.delegate mediaViewControllerDidAddPhoto:weakSelf];
        }
    }];
}

- (IBAction)liveBroadcast:(id)sender {
    if (![WLNetwork sharedNetwork].reachable) {
        [WLToast showWithMessage:@"no_internet_connection".ls];
        return;
    }
    __weak typeof(self)weakSelf = self;
    [WLFollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        if ([weakSelf.delegate respondsToSelector:@selector(mediaViewControllerDidOpenLiveBroadcast:)]) {
            [weakSelf.delegate mediaViewControllerDidOpenLiveBroadcast:weakSelf];
        }
    }];
}

// MARK: - Custom animation

- (void)dropDownCollectionView {
    self.primaryConstraint.defaultState = NO;
    [UIView animateWithDuration:1 delay:0.2 usingSpringWithDamping:0.6 initialSpringVelocity:0.3 options:0 animations:^{
        self.primaryConstraint.defaultState = YES;
    } completion:nil];
}

// MARK: - WLNetwork

- (void)networkDidChangeReachability:(WLNetwork *)network {
    [self.dataSource reload];
}

// MARK: - WLPresentingImageViewDelegate

- (UIView *)presentingImageView:(WLPresentingImageView *)presentingImageView dismissingViewForCandy:(Candy *)candy {
    __weak typeof(self)weakSelf = self;
    StreamItem *item = [self.streamView itemPassingTest:^BOOL(StreamItem *item) {
        return item.entry == candy && item.metrics == weakSelf.candyMetrics;
    }];
    [self.streamView scrollRectToVisible:item.frame animated:NO];
    return item.view;
}

// MARK: - EntryNotifying

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(Entry *)entry event:(enum EntryUpdateEvent)event {
    if (event == EntryUpdateEventLiveBroadcastsChanged) {
        [self.dataSource reload];
    }
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return self.wrap == entry;
}

@end
