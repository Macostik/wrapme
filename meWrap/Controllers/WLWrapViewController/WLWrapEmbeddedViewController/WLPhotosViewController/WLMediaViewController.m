//
//  WLMediaViewController.m
//  
//
//  Created by Yura Granchenko on 10/06/15.
//
//

#import "WLCandiesCell.h"
#import "WLCandyViewController.h"
#import "WLComposeBar.h"
#import "WLWrapCell.h"
#import "WLCandyCell.h"
#import "NSObject+NibAdditions.h"
#import "WLPresentingImageView.h"
#import "WLHistoryViewController.h"
#import "WLMediaViewController.h"
#import "WLUploadingView.h"
#import "WLFollowingViewController.h"
#import "WLWhatsUpSet.h"
#import "WLBadgeLabel.h"
#import "WLUploadingQueue.h"
#import "WLNetwork.h"

static CGFloat WLCandiesHistoryDateHeaderHeight = 42.0f;

@interface WLMediaViewController () <WLPresentingImageViewDelegate, EntryNotifying>

@property (strong, nonatomic) IBOutlet PaginatedStreamDataSource *dataSource;
@property (strong, nonatomic) IBOutlet LayoutPrioritizer *primaryConstraint;
@property (weak, nonatomic) IBOutlet WLUploadingView *uploadingView;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;

@property (strong, nonatomic) WLHistory *history;

@end

@implementation WLMediaViewController

@dynamic delegate;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    StreamView *streamView = self.dataSource.streamView;
    streamView.contentInset = streamView.scrollIndicatorInsets;
    
    __weak typeof(self)weakSelf = self;
    [self.dataSource.autogeneratedMetrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
        return roundf((weakSelf.view.width/2.5f + WLCandiesHistoryDateHeaderHeight));
    }];
    
    [self.dataSource.autogeneratedMetrics setFinalizeAppearing:^(StreamItem *item, id entry) {
        WLCandiesCell *cell = (id)item.view;
        [cell.dataSource.autogeneratedMetrics setSelection:^(StreamItem *item, Candy *candy) {
            WLCandyCell *cell = (id)item.view;
            if (candy.valid && cell.coverView.image != nil) {
                WLHistoryViewController *historyViewController = (id)[candy viewController];
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
        }];
    }];
    
    [self.dataSource setAppendableBlock:^BOOL(PaginatedStreamDataSource *dataSource) {
        return weakSelf.wrap.uploaded;
    }];
    if (self.wrap.requiresFollowing && [WLNetwork sharedNetwork].reachable) {
        self.wrap.candies = nil;
    }
    self.history = [WLHistory historyWithWrap:self.wrap checkCompletion:YES];
    
    [self.dataSource setRefreshableWithStyle:Refresher.Orange];
    
    [self firstLoadRequest];
    
    self.uploadingView.queue = [WLUploadingQueue queueForEntriesOfClass:[Candy class]];
    
    [[WLNetwork sharedNetwork] addReceiver:self];
    
    if (self.wrap.candies.nonempty) {
        [self dropDownCollectionView];
    }
}

- (void)firstLoadRequest {
    if (self.wrap.candies.nonempty) {
        if (self.history.entries.count > [NSUserDefaults standardUserDefaults].pageSize) {
            [self.history newer:nil failure:nil];
        } else {
            [self.history fresh:nil failure:nil];
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
            weakSelf.badge.intValue = unreadCandyCounter;
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
    WLHistoryItem *historyItem = [self.history itemWithCandy:candy];
    if (historyItem) {
        __weak typeof(self)weakSelf = self;
        StreamItem *item = [self.dataSource.streamView itemPassingTest:^BOOL(StreamItem *item) {
            return item.entry == historyItem && item.metrics == weakSelf.dataSource.autogeneratedMetrics;
        }];
        [self.dataSource.streamView scrollRectToVisible:item.frame animated:NO];
        WLCandiesCell *candiesCell = (id)item.view;
        if (candiesCell) {
            item = [candiesCell.dataSource.streamView itemPassingTest:^BOOL(StreamItem *item) {
                return item.entry == candy && item.metrics == candiesCell.dataSource.autogeneratedMetrics;
            }];
            [candiesCell.dataSource.streamView scrollRectToVisible:item.frame animated:NO];
            return item.view;
        }
    }
    return nil;
}

@end
