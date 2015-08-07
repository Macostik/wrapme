//
//  WLPhotosViewController.m
//  
//
//  Created by Yura Granchenko on 10/06/15.
//
//

#import "WLCandiesCell.h"
#import "WLCandyViewController.h"
#import "WLComposeBar.h"
#import "WLRefresher.h"
#import "WLLoadingView.h"
#import "UILabel+Additions.h"
#import "WLWrapCell.h"
#import "UIView+AnimationHelper.h"
#import "WLCandyCell.h"
#import "NSObject+NibAdditions.h"
#import "WLBasicDataSource.h"
#import "UIScrollView+Additions.h"
#import "WLContributorsViewController.h"
#import "UIView+QuatzCoreAnimations.h"
#import "UIFont+CustomFonts.h"
#import "WLChronologicalEntryPresenter.h"
#import "WLPresentingImageView.h"
#import "WLHistoryViewController.h"
#import "WLPhotosViewController.h"
#import "WLNavigationHelper.h"
#import "WLLayoutPrioritizer.h"
#import "WLUploadingView.h"

static CGFloat WLCandiesHistoryDateHeaderHeight = 42.0f;

@interface WLPhotosViewController () <WLPresentingImageViewDelegate, WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;
@property (strong, nonatomic) IBOutlet WLLayoutPrioritizer *primaryConstraint;
@property (weak, nonatomic) IBOutlet WLUploadingView *uploadingView;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;

@property (strong, nonatomic) WLHistory *history;

@end

@implementation WLPhotosViewController

@dynamic delegate;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    __weak typeof(self)weakSelf = self;
    [self.dataSource setItemSizeBlock:^CGSize(id entry, NSUInteger index) {
        return CGSizeMake(weakSelf.collectionView.width, (weakSelf.collectionView.width/2.5f + WLCandiesHistoryDateHeaderHeight));
    }];
    
    [self.dataSource setAppendableBlock:^BOOL(id<WLBaseOrderedCollection> items) {
        return weakSelf.wrap.uploaded;
    }];
    self.history = [WLHistory historyWithWrap:self.wrap checkCompletion:YES];
    self.dataSource.items = self.history;
    
    [self.dataSource setRefreshableWithStyle:WLRefresherStyleOrange];
    
    [self firstLoadRequest];
    
    self.uploadingView.queue = [WLUploadingQueue queueForEntriesOfClass:[WLCandy class]];
    
    [[WLNetwork network] addReceiver:self];
    
    if (self.wrap.candies.nonempty) {
        [self dropDownCollectionView];
    }
    self.addPhotoButton.hidden = self.wrap.requiresFollowing;
    
    [[WLWrap notifier] addReceiver:self];
}

- (void)firstLoadRequest {
    if (self.history.entries.count > WLPageSize) {
        [self.history newer:nil failure:nil];
    } else {
        [self.history fresh:nil failure:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.wrap.valid) {
        [self.wrap.candies all:^(WLCandy *candy) {
            [candy markAsRead];
        }];
        [self.dataSource reload];
    } else {
        __weak typeof(self)weakSelf = self;
        run_after(0.5f, ^{
            [weakSelf.navigationController popViewControllerAnimated:NO];
        });
    }
    [self.uploadingView update];
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLEntry *)entry {
    self.addPhotoButton.hidden = self.wrap.requiresFollowing;
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return self.wrap == entry;
}

// MARK: - User Actions

- (IBAction)addPhoto:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(photosViewControllerDidAddPhoto:)]) {
        [self.delegate photosViewControllerDidAddPhoto:self];
    }
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

// MARK: - WLCandyCellDelegate

- (void)candyCell:(WLCandyCell *)cell didSelectCandy:(WLCandy *)candy {
    WLHistoryViewController *historyViewController = (id)[candy viewController];
    if (historyViewController) {
        WLPresentingImageView *presentingImageView = [WLPresentingImageView sharedPresenting];
        presentingImageView.delegate = self;
        __weak __typeof(self)weakSelf = self;
        [presentingImageView presentingCandy:candy completion:^(BOOL flag) {
            [weakSelf.navigationController pushViewController:historyViewController animated:NO];
        }];
        historyViewController.presentingImageView = presentingImageView;
    }
}

// MARK: - WLPresentingImageViewDelegate

- (CGRect)presentImageView:(WLPresentingImageView *)presentingImageView getFrameCandyCell:(WLCandy *)candy {
    WLCandyCell *candyCell = [self presentedCandyCell:candy scrollToObject:NO];
    return [[self parentViewController].view convertRect:candyCell.frame fromView:candyCell.superview];
}

- (CGRect)dismissImageView:(WLPresentingImageView *)presentingImageView getFrameCandyCell:(WLCandy *)candy {
    WLCandyCell *candyCell = [self presentedCandyCell:candy scrollToObject:YES];
    return [[self parentViewController].view convertRect:candyCell.frame fromView:candyCell.superview];
}

- (WLCandyCell *)presentedCandyCell:(WLCandy *)candy scrollToObject:(BOOL)scroll {
    WLHistoryItem *historyItem = [self.history itemWithCandy:candy];
    if (historyItem) {
        NSUInteger index = [[self.history entries] indexOfObject:historyItem];
        if (index != NSNotFound) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            if (scroll) {
                [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
            }
            [self.collectionView layoutIfNeeded];
            WLCandiesCell *candiesCell = (id)[self.collectionView cellForItemAtIndexPath:indexPath];
            if (scroll) {
                [self.collectionView scrollRectToVisible:candiesCell.frame animated:NO];
            }
            if (candiesCell) {
                NSUInteger index = [historyItem.entries indexOfObject:candy];
                if (index != NSNotFound) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    [candiesCell.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
                    [candiesCell.collectionView layoutIfNeeded];
                    WLCandyCell *candyCell = (id)[candiesCell.collectionView cellForItemAtIndexPath:indexPath];
                    if (candyCell) {
                        return candyCell;
                    }
                }
            }
        }
    }
    return nil;
}

@end
