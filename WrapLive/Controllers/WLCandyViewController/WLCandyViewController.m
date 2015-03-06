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
#import "WLImageViewCell.h"
#import "WLComposeBar.h"
#import "WLHistory.h"
#import "WLImageFetcher.h"
#import "WLNetwork.h"
#import "WLKeyboard.h"
#import "WLNavigation.h"
#import "WLSession.h"
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
#import "WLProgressBar+WLContribution.h"

@interface WLCandyViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, WLKeyboardBroadcastReceiver, WLEntryNotifyReceiver, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate, WLNetworkReceiver, WLDeviceOrientationBroadcastReceiver, WLBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet WLButton *commentButton;
@property (weak, nonatomic) IBOutlet WLIconButton *actionButton;
@property (weak, nonatomic) IBOutlet WLLabel *postLabel;
@property (weak, nonatomic) IBOutlet WLLabel *timeLabel;
@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;

@property (strong, nonatomic) WLComment *lastComment;
@property (nonatomic) BOOL scrolledToInitialItem;

@property (weak, nonatomic) IBOutlet WLImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet WLLabel *lastCommentLabel;

@property (weak, nonatomic) UISwipeGestureRecognizer* leftSwipeGestureRecognizer;
@property (weak, nonatomic) UISwipeGestureRecognizer* rightSwipeGestureRecognizer;

@property (strong, nonatomic) WLHistoryItem *historyItem;

@property (strong, nonatomic) WLHistory *history;
@property (assign, nonatomic) CGPoint scrollPositionBeforeRotation;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewContstraint;

@property (strong, nonatomic) WLWrap* wrap;

@end

@implementation WLCandyViewController

@synthesize candy = _candy;

- (void)dealloc {
    [self.collectionView removeObserver:self forKeyPath:@"contentOffset" context:NULL];
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.wrap = _candy.wrap;
    
    if (!self.history) {
        self.history = [WLHistory historyWithWrap:self.wrap];
        _historyItem = [self.history itemWithCandy:_candy];
    }
	
	[[WLCandy notifier] addReceiver:self];
    [[WLNetwork network] addReceiver:self];
    
    UISwipeGestureRecognizer* leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToNextHistoryItem)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    leftSwipe.delegate = self;
    [self.collectionView addGestureRecognizer:leftSwipe];
    self.leftSwipeGestureRecognizer = leftSwipe;
    [self.collectionView.panGestureRecognizer requireGestureRecognizerToFail:leftSwipe];
    
    UISwipeGestureRecognizer* rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToPreviousHistoryItem)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    rightSwipe.delegate = self;
    [self.collectionView addGestureRecognizer:rightSwipe];
    self.rightSwipeGestureRecognizer = rightSwipe;
    [self.collectionView.panGestureRecognizer requireGestureRecognizerToFail:rightSwipe];
    
    self.commentButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    [self refresh:self.candy];
    
    [self.collectionView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (!self.scrolledToInitialItem) return;
    CGFloat indexPosition = roundf(self.collectionView.contentOffset.x / self.collectionView.width);
    if ([self.historyItem.entries containsIndex:indexPosition]) {
        self.candy = [self.historyItem.entries objectAtIndex:indexPosition];
    }
    [self applyFadeEffect];
}

- (void)refresh {
    [self refresh:self.candy];
}

- (void)refresh:(WLCandy*)candy {
    [candy fetch:^(id object) { } failure:^(NSError *error) { }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.lastComment = nil;
    [self updateOwnerData];
    [self.collectionView reloadData];
    if (self.showCommentViewController) {
        [self.commentButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.scrolledToInitialItem = YES;
    [WLHintView showCandySwipeHintView];
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

- (void)swipeToNextHistoryItem {
    if (self.historyItem.completed) {
        if ([self swipeToHistoryItemAtIndex:[self.history.entries indexOfObject:self.historyItem] + 1]) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
            [self.collectionView leftPush];
            self.candy = [self.historyItem.entries firstObject];
        } else if (!self.history.completed) {
            __weak typeof(self)weakSelf = self;
            [self.history older:^(NSOrderedSet *orderedSet) {
                [weakSelf swipeToNextHistoryItem];
            } failure:^(NSError *error) {
                
            }];
        }
    } else {
        [self fetchOlder:self.candy];
    }
}

- (void)swipeToPreviousHistoryItem {
    if ([self swipeToHistoryItemAtIndex:[self.history.entries indexOfObject:self.historyItem] - 1]) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[self.historyItem.entries count] - 1 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        [self.collectionView rightPush];
        self.candy = [self.historyItem.entries lastObject];
    }
}

- (void)setCandy:(WLCandy *)candy {
    if (candy != _candy && candy.valid) {
        _candy = candy;
        [self updateOwnerData];
        [self refresh];
    }
}

- (void)setLastComment:(WLComment *)lastComment {
    if (lastComment != _lastComment) {
        _lastComment = lastComment;
        self.avatarImageView.url = _lastComment.contributor.picture.small;
        self.lastCommentLabel.text = _lastComment.valid ? _lastComment.text :@"";
        [self.progressBar setContribution:lastComment];
    }
}

- (void)updateOwnerData {
    self.actionButton.iconName = _candy.deletable ? @"trash" : @"exclamationTriangle";
    [self setCommentButtonTitle:_candy];
    self.postLabel.text = [NSString stringWithFormat:WLLS(@"Posted by %@"), _candy.contributor.name];
    NSString *timeAgoString = [_candy.createdAt.timeAgoStringAtAMPM stringByCapitalizingFirstCharacter];
    self.timeLabel.text = timeAgoString;
    self.lastComment = _candy.comments.lastObject;
}

- (void)setCommentButtonTitle:(WLCandy *)candy {
    NSString *title = WLLS(@"Comment");
    if (candy.commentCount == 1) {
        title = WLLS(@"1 comment");
    } else if (candy.commentCount > 1){
        title = [NSString stringWithFormat:WLLS(@"%i comments"), (int)candy.commentCount];
    }
    [self.commentButton setTitle:title forState:UIControlStateNormal];
}

- (BOOL)swipeToHistoryItemAtIndex:(NSUInteger)index {
    if ([self.history.entries containsIndex:index]) {
        WLHistoryItem* historyItem = [self.history.entries objectAtIndex:index];
        self.historyItem = historyItem;
        return YES;
    }
    return NO;
}

- (void)applyFadeEffect {
    for (WLImageViewCell* cell in [self.collectionView visibleCells]) {
        CGFloat alpha = (cell.width - ABS(cell.x - self.collectionView.contentOffset.x)) / cell.width;
        cell.alpha = alpha;
    }
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

- (void)notifier:(WLEntryNotifier *)notifier candyAdded:(WLCandy *)candy {
    if ([self.historyItem.entries containsObject:candy]) {
        [self performSelector:@selector(scrollToCurrentCandy) withObject:nil afterDelay:0.0f];
    }
}

- (void)notifier:(WLEntryNotifier *)notifier candyDeleted:(WLCandy *)candy {
    if (candy == self.candy) {
        [WLToast showWithMessage:WLLS(@"This candy is no longer avaliable.")];
        self.candy = nil;
    }
    
    if (self.historyItem.entries.nonempty) {
        [self performSelector:@selector(scrollToCurrentCandy) withObject:nil afterDelay:0.0f];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)notifier:(WLEntryNotifier *)notifier candyUpdated:(WLCandy *)candy {
    if (candy == self.candy) {
        [self updateOwnerData];
    }
}

- (WLWrap *)notifierPreferredWrap:(WLEntryNotifier *)notifier {
    return self.wrap;
}

- (NSNumber *)peferedOrderEntry:(WLBroadcaster *)broadcaster {
    return @(2);
}

- (void)scrollToCurrentCandy {
    WLCandy *candy = self.candy;
    [self.collectionView reloadData];
    [self.collectionView layoutIfNeeded];
    if (candy.valid) {
        NSUInteger index = [self.historyItem.entries indexOfObject:candy];
        if (index != NSNotFound) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]
                                            atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        }
    }
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

- (IBAction)downloadCandy:(id)sender {
    [self.candy download:^{
    } failure:^(NSError *error) {
        [error show];
    }];
    [WLToast showPhotoDownloadingMessage];
}

- (IBAction)navigationButtonClick:(WLIconButton *)sender {
    if (self.candy.deletable) {
        [self.candy remove:^(id object) {
            [WLToast showWithMessage:WLLS(@"Candy was deleted successfully.")];
        } failure:^(NSError *error) {
            [error show];
        }];
    } else {
        [MFMailComposeViewController messageWithCandy:self.candy];
    }
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
    CGFloat xPosition = Smoothstep(.0, 1.0, self.collectionView.contentOffset.x / self.collectionView.contentSize.width);
    CGFloat yPosition = self.collectionView.contentOffset.y / self.collectionView.contentSize.height;
    self.scrollPositionBeforeRotation = CGPointMake(xPosition, yPosition);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation; {
    CGPoint newContentOffset = CGPointMake(self.scrollPositionBeforeRotation.x * self.collectionView.contentSize.width,
                                           self.scrollPositionBeforeRotation.y * self.collectionView.contentSize.height);
 
    [self.collectionView trySetContentOffset:newContentOffset animated:NO];
    self.collectionView.alpha = 1;
}

#pragma mark - WLScrollViewDelegate method

- (UIView *)viewForZoomingInScrollView:(WLScrollView *)scrollView {
    return [scrollView isKindOfClass:[WLScrollView class]] ? scrollView.zoomingView : nil;
}

static CGFloat WLTopContraintConstant = -20.0f;

- (IBAction)movingDetailViews {
   BOOL hide = self.topViewConstraint.constant == WLTopContraintConstant;
    [UIView performAnimated:YES animation:^{
        self.topViewConstraint.constant = hide ? -self.topView.height + WLTopContraintConstant : WLTopContraintConstant;
        self.bottomViewContstraint.constant = hide ? -self.bottomView.height : .0f;
        [self.view layoutIfNeeded];
    }];
}

@end
