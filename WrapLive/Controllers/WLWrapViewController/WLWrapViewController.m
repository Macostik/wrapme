
//
//  WLWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapViewController.h"
#import "WLCandiesCell.h"
#import "WLNavigationHelper.h"
#import "WLCandyViewController.h"
#import "WLComposeBar.h"
#import "WLRefresher.h"
#import "WLChatViewController.h"
#import "WLLoadingView.h"
#import "WLEditWrapViewController.h"
#import "UILabel+Additions.h"
#import "WLToast.h"
#import "WLStillPictureViewController.h"
#import "WLWrapCell.h"
#import "UIView+AnimationHelper.h"
#import "WLCandyCell.h"
#import "NSObject+NibAdditions.h"
#import "WLBasicDataSource.h"
#import "UIScrollView+Additions.h"
#import "WLContributorsViewController.h"
#import "WLBadgeLabel.h"
#import "UIView+QuatzCoreAnimations.h"
#import "UIFont+CustomFonts.h"
#import "WLHintView.h"
#import "WLChronologicalEntryPresenter.h"
#import "WLPresentingImageView.h"
#import "WLHistoryViewController.h"


static CGFloat WLCandiesHistoryDateHeaderHeight = 42.0f;

@interface WLWrapViewController () <WLStillPictureViewControllerDelegate, WLPresentingImageViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) WLHistory *history;

@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;
@property (weak, nonatomic) IBOutlet UIButton *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *messageCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@end

@implementation WLWrapViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self addNotifyReceivers];
        [[WLNetwork network] addReceiver:self];
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.nameLabel.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    self.collectionView.contentInset = self.collectionView.scrollIndicatorInsets;
    
    if (!self.wrap.valid) {
        return;
    }
    
    // force set hostory mode to remove timeline from UI but keep it in code
    
    __weak typeof(self)weakSelf = self;
    [self.dataSource setItemSizeBlock:^CGSize(id entry, NSUInteger index) {
        return CGSizeMake(weakSelf.collectionView.width, (weakSelf.collectionView.width/2.5f + WLCandiesHistoryDateHeaderHeight));
    }];
    
    [self.dataSource setAppendableBlock:^BOOL(id<WLDataSourceItems> items) {
        return weakSelf.wrap.uploaded;
    }];
    self.history = [WLHistory historyWithWrap:self.wrap checkCompletion:YES];
    self.dataSource.items = self.history;
    
    [self.dataSource setRefreshableWithStyle:WLRefresherStyleOrange];
    
    [self firstLoadRequest];
    
    if (self.wrap.candies.nonempty) {
        [self dropDownCollectionView];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIEdgeInsets inset = self.collectionView.contentInset;
    inset.top = self.contributorsLabel.superview.height;
    self.collectionView.contentInset = inset;
}

- (void)updateWrapData {
    [self.nameLabel setTitle:WLString(self.wrap.name) forState:UIControlStateNormal];
    self.contributorsLabel.text = [self.wrap contributorNames];
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
        [self updateNotificationCouter];
        [self updateWrapData];
    } else {
        __weak typeof(self)weakSelf = self;
        run_after(0.5f, ^{
            [weakSelf.navigationController popViewControllerAnimated:NO];
        });
    }
    if ([self.wrap isFirstCreated]) {
        [WLHintView showInviteHintViewInView:[UIWindow mainWindow] withFocusToView:self.inviteButton];
    }
}

- (void)updateNotificationCouter {
    self.messageCountLabel.intValue = [self.wrap unreadNotificationsMessageCount];
}

// MARK: - User Actions

- (IBAction)editWrapClick:(id)sender {
    WLEditWrapViewController* editWrapViewController = [WLEditWrapViewController new];
    editWrapViewController.wrap = self.wrap;
    [self presentViewController:editWrapViewController animated:NO completion:nil];
}

- (IBAction)addPhoto:(id)sender {
    WLStillPictureViewController *stillPictureViewController = [WLStillPictureViewController stillPictureViewController];
    stillPictureViewController.wrap = self.wrap;
    stillPictureViewController.mode = WLStillPictureModeDefault;
    stillPictureViewController.delegate = self;
    stillPictureViewController.startFromGallery = NO;
    [self presentViewController:stillPictureViewController animated:NO completion:nil];
}

// MARK: - WLEntryNotifyReceiver

- (void)addNotifyReceivers {
    __weak typeof(self)weakSelf = self;
    
    [WLWrap notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setEntryBlock:^WLEntry *{
            return weakSelf.wrap;
        }];
        receiver.didAddBlock = receiver.didUpdateBlock = ^(WLWrap *wrap) {
            [weakSelf updateWrapData];
        };
        receiver.willDeleteBlock = ^(WLWrap *wrap) {
            [weakSelf.navigationController popToRootViewControllerAnimated:NO];
            [WLToast showMessageForUnavailableWrap:wrap];
        };
    }];
    
    [WLCandy notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setContainingEntryBlock:^WLEntry *{
            return weakSelf.wrap;
        }];
        [receiver setDidAddBlock:^(WLCandy *candy) {
            if ([weakSelf isViewLoaded]) {
                [candy markAsRead];
            }
        }];
    }];
    
    [WLMessage notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setContainingEntryBlock:^WLEntry *{
            return weakSelf.wrap;
        }];
        receiver.didAddBlock = receiver.didDeleteBlock = ^(WLMessage *message) {
            [weakSelf updateNotificationCouter];
        };
    }];
}

// MARK: - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    WLWrap* wrap = controller.wrap ? : self.wrap;
    if (self.wrap != wrap) {
        self.view = nil;
        self.wrap = wrap;
    }
    [wrap uploadPictures:pictures];
    [self.collectionView setMinimumContentOffsetAnimated:NO];
	[self dismissViewControllerAnimated:NO completion:nil];
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
    [self dismissViewControllerAnimated:NO completion:nil];
}

// MARK: - Custom animation

- (void)dropDownCollectionView {
    self.collectionView.transform = CGAffineTransformMakeTranslation(0, -self.view.height);
    [UIView animateWithDuration:1 delay:0.2 usingSpringWithDamping:0.6 initialSpringVelocity:0.3 options:0 animations:^{
        self.collectionView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
    }];
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
    return [self.view convertRect:candyCell.frame fromView:candyCell.superview];
}

- (CGRect)dismissImageView:(WLPresentingImageView *)presentingImageView getFrameCandyCell:(WLCandy *)candy {
    WLCandyCell *candyCell = [self presentedCandyCell:candy scrollToObject:YES];
    return [self.view convertRect:candyCell.frame fromView:candyCell.superview];
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
