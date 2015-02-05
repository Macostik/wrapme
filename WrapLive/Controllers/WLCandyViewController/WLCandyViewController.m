//
//  WLWrapDataViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "MFMailComposeViewController+Additions.h"
#import "NSDate+Additions.h"
#import "NSDate+Formatting.h"
#import "NSString+Additions.h"
#import "UIActionSheet+Blocks.h"
#import "UIAlertView+Blocks.h"
#import "UIFont+CustomFonts.h"
#import "UIScrollView+Additions.h"
#import "UIView+QuatzCoreAnimations.h"
#import "UIView+Shorthand.h"
#import "WLAPIManager.h"
#import "WLCandiesRequest.h"
#import "WLCandy.h"
#import "WLCandyViewController.h"
#import "WLComment.h"
#import "WLCommentCell.h"
#import "WLImageViewCell.h"
#import "WLComposeBar.h"
#import "WLHistory.h"
#import "WLImageFetcher.h"
#import "WLNetwork.h"
#import "WLKeyboard.h"
#import "WLNavigation.h"
#import "WLSession.h"
#import "WLSoundPlayer.h"
#import "WLToast.h"
#import "WLUser.h"
#import "WLWrap.h"
#import "WLEntryNotifier.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "UIView+AnimationHelper.h"
#import "NSOrderedSet+Additions.h"
#import "WLHintView.h"
#import "WLCircleImageView.h"
#import "WLLabel.h"
#import "WLScrollView.h"
#import "WLIconButton.h"
#import "WLDeviceOrientationBroadcaster.h"

@interface WLCandyViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, WLKeyboardBroadcastReceiver, WLEntryNotifyReceiver, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate, WLNetworkReceiver, WLDeviceOrientationBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet WLButton *commentButton;
@property (weak, nonatomic) IBOutlet WLIconButton *actionButton;
@property (weak, nonatomic) IBOutlet WLLabel *postLabel;

@property (nonatomic) BOOL shouldLoadMoreCandies;
@property (nonatomic) BOOL scrolledToInitialItem;

@property (strong, nonatomic) WLImageViewCell* candyCell;

@property (weak, nonatomic) IBOutlet WLImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet WLLabel *lastCommentLabel;

@property (weak, nonatomic) UISwipeGestureRecognizer* leftSwipeGestureRecognizer;
@property (weak, nonatomic) UISwipeGestureRecognizer* rightSwipeGestureRecognizer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewConstraint;

@property (strong, nonatomic) WLHistoryItem *historyItem;

@property (strong, nonatomic) WLHistory *history;
@property (assign, nonatomic) CGPoint scrollPositionBeforeRotation;
@property (assign, nonatomic) BOOL isHide;

@end

@implementation WLCandyViewController

@synthesize candy = _candy;


- (void)viewDidLoad {
    [super viewDidLoad];
        
    if (!self.history) {
        self.history = [[WLHistory alloc] init];
        [self.history addEntries:[_candy.wrap candies]];
        _historyItem = [self.history itemWithCandy:_candy];
    }
	
	[[WLCandy notifier] addReceiver:self];
    [[WLComment notifier] addReceiver:self];
    [[WLNetwork network] addReceiver:self];
    
    UISwipeGestureRecognizer* leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeft)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    leftSwipe.delegate = self;
    [self.collectionView addGestureRecognizer:leftSwipe];
    self.leftSwipeGestureRecognizer = leftSwipe;
    [self.collectionView.panGestureRecognizer requireGestureRecognizerToFail:leftSwipe];
    
    UISwipeGestureRecognizer* rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeRight)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    rightSwipe.delegate = self;
    [self.collectionView addGestureRecognizer:rightSwipe];
    self.rightSwipeGestureRecognizer = rightSwipe;
    [self.collectionView.panGestureRecognizer requireGestureRecognizerToFail:rightSwipe];
    
    self.commentButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.isHide = YES;
    
    [self refresh:_candy];
}

- (void)refresh {
    WLCandy* candy = self.candy ? : _candy;
    [self refresh:candy];
}

- (void)refresh:(WLCandy*)candy {
    [candy fetch:^(id object) { } failure:^(NSError *error) { }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateOwnerData:self.candy];
    [self.collectionView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.scrolledToInitialItem = YES;
    [WLHintView showCandySwipeHintView];
    [self showDetailViewsAfterDelay:5.0f];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    NSUInteger index = [self.historyItem.entries indexOfObject:_candy];
    if (!self.scrolledToInitialItem && index != NSNotFound) {
        [self.collectionView setContentOffset:CGPointMake(index*self.collectionView.width, 0)];
    }
}

- (void)setHistoryItem:(WLHistoryItem *)historyItem {
    _historyItem = historyItem;
    [self.collectionView reloadData];
}

- (WLCandy *)candy {
    WLImageViewCell* cell = self.candyCell;
    if (cell) {
        return cell.entry;
    }
    NSUInteger index = floorf(self.collectionView.contentOffset.x/self.collectionView.width);
    return [self.historyItem.entries tryObjectAtIndex:index];
}

- (WLImageViewCell *)candyCell {
    WLImageViewCell* candyCell = [[self.collectionView visibleCells] lastObject];
    return candyCell;
}

- (void)fetchOlder:(WLCandy*)candy {
    WLHistoryItem *historyItem = self.historyItem;
    if (historyItem.completed || !candy) return;
    NSUInteger count = [historyItem.entries count];
    NSUInteger index = [historyItem.entries indexOfObject:candy];
    BOOL shouldAppendCandies = (count >= 3) ? index > count - 3 : YES;
    if (shouldAppendCandies) {
        __weak typeof(self)weakSelf = self;
        [historyItem older:^(NSOrderedSet *candies) {
            if (candies.nonempty) [weakSelf.collectionView reloadData];
        } failure:^(NSError *error) {
            if (error.isNetworkError) {
                historyItem.completed = YES;
            }
        }];
    }
}

- (void)didSwipeLeft {
    if (self.historyItem.completed) {
        if ([self swipeToHistoryItemAtIndex:[self.history.entries indexOfObject:self.historyItem] + 1]) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
            [self.collectionView leftPush];
        }
    } else {
        [self fetchOlder:self.candy];
    }
}

- (void)didSwipeRight {
    if ([self swipeToHistoryItemAtIndex:[self.history.entries indexOfObject:self.historyItem] - 1]) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[self.historyItem.entries count] - 1 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        [self.collectionView rightPush];
    }
}

- (void)updateOwnerData:(WLCandy *)candy {
    self.avatarImageView.url = candy.contributor.picture.small;
    [self.actionButton setupWithName:candy.deletable ? @"trash" : @"warning"
                               color:[UIColor whiteColor]
                                size:self.actionButton.width/2];
    self.postLabel.text = [NSString stringWithFormat:@"Posted by %@,\n%@", candy.contributor.name,
                                                                           [candy.createdAt.timeAgoStringAtAMPM capitalizedString]];
    WLComment *comment = candy.comments.lastObject;
    self.lastCommentLabel.text = comment.valid ? comment.text :@"";
}

- (BOOL)swipeToHistoryItemAtIndex:(NSUInteger)index {
    if ([self.history.entries containsIndex:index]) {
        WLHistoryItem* historyItem = [self.history.entries objectAtIndex:index];
        self.historyItem = historyItem;
        return YES;
    }
    return NO;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.leftSwipeGestureRecognizer) {
        return self.collectionView.contentOffset.x == self.collectionView.maximumContentOffset.x;
    } else if (gestureRecognizer == self.rightSwipeGestureRecognizer) {
        return self.collectionView.contentOffset.x == 0;
    }
    return YES;
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier candyDeleted:(WLCandy *)candy {
    [WLToast showWithMessage:WLLS(@"This candy is no longer avaliable.")];
    NSMutableOrderedSet* candies = self.historyItem.entries;
    [candies removeObject:candy];
    if (candies.nonempty) {
        [self.collectionView reloadData];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)notifier:(WLEntryNotifier *)notifier candyUpdated:(WLCandy *)candy {
    [self updateOwnerData:candy];
}

- (WLCandy *)notifierPreferredCandy:(WLEntryNotifier *)notifier {
    return self.candy;
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
    WLCandy* candy = self.candy;
    __weak __typeof(self)weakSelf = self;
    if (candy.valid && candy.wrap.valid) {
        BOOL animate = self.interfaceOrientation == UIInterfaceOrientationPortrait ||
                       self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown;
        [weakSelf.navigationController popViewControllerAnimated:animate];
    } else {
        [weakSelf.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (IBAction)navigationButtonClick:(WLIconButton *)sender {
    self.isHide = NO;
    __weak __typeof(self)weakSelf = self;
    if ([sender.iconName isEqualToString:@"cloudDownload"]) {
        [self.candy download:^{
        } failure:^(NSError *error) {
            [error show];
        }];
        [WLToast showPhotoDownloadingMessage];
    } else if ([sender.iconName isEqualToString:@"trash"]) {
        if (self.candy.deletable) {
            [self.candy remove:^(id object) {
                [WLToast showWithMessage:WLLS(@"Candy was deleted successfully.")];;
                [weakSelf dismissViewControllerAnimated:NO completion:nil];
            } failure:^(NSError *error) {
                [error show];
            }];
        }
    } else {
        [MFMailComposeViewController messageWithCandy:self.candy];
    }
}

static CGFloat WLTopContraintConstant = -20.0f;

- (IBAction)onTapGestureRecognize:(id)sender {
    BOOL hide = self.topViewConstraint.constant == WLTopContraintConstant;
    [self hideDetailViews:hide];
}

- (void)showDetailViewsAfterDelay:(CGFloat)sec {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showDetailViewsAfterDelay:) object:nil];
    [self hideDetailViews:NO];
    __weak __typeof(self)weakSelf = self;
    run_after(sec, ^{
        [weakSelf hideDetailViews:weakSelf.isHide];
    });
}

- (void)hideDetailViews:(BOOL)hide {
    [UIView performAnimated:YES animation:^{
        self.topViewConstraint.constant = hide ? -self.topView.height + WLTopContraintConstant : WLTopContraintConstant;
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.historyItem.entries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLImageViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:WLImageViewCellIdentifier forIndexPath:indexPath];
    WLCandy* candy = [self.historyItem.entries tryObjectAtIndex:indexPath.item];
    if (candy.valid) {
        [self fetchOlder:candy];
        cell.entry = candy;
    } else {
        cell.entry = nil;
    }
   
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return collectionView.size;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat indexPosition = roundf(self.collectionView.contentOffset.x / self.collectionView.width);
    if ([self.historyItem.entries containsIndex:indexPosition]) {
        WLCandy *candy = [self.historyItem.entries objectAtIndex:indexPosition];
        [self updateOwnerData:candy];
    }
}

#pragma mark - WLNetworkReceiver

- (void)networkDidChangeReachability:(WLNetwork *)network {
    [self.collectionView reloadData];
}

#pragma mark - WLDeviceOrientationBroadcastReceiver

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.collectionView.alpha = 0;
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    self.scrollPositionBeforeRotation = CGPointMake(self.collectionView.contentOffset.x / self.collectionView.contentSize.width,
                                                    self.collectionView.contentOffset.y / self.collectionView.contentSize.height);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation; {
    CGPoint newContentOffset = CGPointMake(self.scrollPositionBeforeRotation.x * self.collectionView.contentSize.width,
                                           self.scrollPositionBeforeRotation.y * self.collectionView.contentSize.height);
    
    [self.collectionView setContentOffset:newContentOffset animated:NO];
    self.collectionView.alpha = 1;
}

#pragma mark - WLScrollViewDelegate method

- (UIView *)viewForZoomingInScrollView:(WLScrollView *)scrollView {
    return [scrollView isKindOfClass:[WLScrollView class]] ? scrollView.zoomingView : nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    [self hideDetailViews:YES];
}

@end

