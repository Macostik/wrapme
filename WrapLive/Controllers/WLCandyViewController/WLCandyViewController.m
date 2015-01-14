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
#import "WLCommentsCell.h"
#import "WLComposeBar.h"
#import "WLHistory.h"
#import "WLImageFetcher.h"
#import "WLImageViewController.h"
#import "WLNetwork.h"
#import "WLKeyboard.h"
#import "WLNavigation.h"
#import "WLRefresher.h"
#import "WLCandyOptionsViewController.h"
#import "WLSession.h"
#import "WLSoundPlayer.h"
#import "WLToast.h"
#import "WLUser.h"
#import "WLWrap.h"
#import "WLEntryNotifier.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "UIView+AnimationHelper.h"
#import "NSOrderedSet+Additions.h"

@interface WLCandyViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, WLComposeBarDelegate, WLKeyboardBroadcastReceiver, WLEntryNotifyReceiver, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate, WLNetworkReceiver>

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBarView;
@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (nonatomic) BOOL shouldLoadMoreCandies;
@property (nonatomic) BOOL scrolledToInitialItem;

@property (readonly, nonatomic) WLCommentsCell* candyCell;

@property (weak, nonatomic) UISwipeGestureRecognizer* leftSwipeGestureRecognizer;
@property (weak, nonatomic) UISwipeGestureRecognizer* rightSwipeGestureRecognizer;

@property (strong, nonatomic) WLHistoryItem *historyItem;

@property (strong, nonatomic) WLHistory *history;

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
    
	self.composeBarView.placeholder = @"Write your comment ...";
	
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
    [self.collectionView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.scrolledToInitialItem = YES;
    if (self.showCommentInputKeyboard) {
        [self.composeBarView becomeFirstResponder];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.collectionView.height - 70, 0);
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
    WLCommentsCell* cell = self.candyCell;
    if (cell) {
        return cell.entry;
    }
    NSUInteger index = floorf(self.collectionView.contentOffset.x/self.collectionView.width);
    return [self.historyItem.entries tryObjectAtIndex:index];
}

- (WLCommentsCell *)candyCell {
    WLCommentsCell* candyCell = [[self.collectionView visibleCells] lastObject];
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
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
            [self.collectionView leftPush];
        }
    } else {
        [self fetchOlder:self.candy];
    }
}

- (void)didSwipeRight {
    if ([self swipeToHistoryItemAtIndex:[self.history.entries indexOfObject:self.historyItem] - 1]) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[self.historyItem.entries count] - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        [self.collectionView rightPush];
    }
}

- (BOOL)swipeToHistoryItemAtIndex:(NSUInteger)index {
    if ([self.history.entries containsIndex:index]) {
        WLHistoryItem* historyItem = [self.history.entries objectAtIndex:index];
        self.historyItem = historyItem;
        [self showDateView];
        return YES;
    }
    return NO;
}

- (void)showDateView {
    self.dateLabel.text = [self.historyItem.date string];
    [UIView beginAnimations:nil context:nil];
    self.dateLabel.superview.alpha = 1.0f;
    [UIView commitAnimations];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideDateView) object:nil];
    [self performSelector:@selector(hideDateView) withObject:nil afterDelay:3];
}

- (void)hideDateView {
    [UIView beginAnimations:nil context:nil];
    self.dateLabel.superview.alpha = 0.0f;
    [UIView commitAnimations];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return otherGestureRecognizer == self.collectionView.panGestureRecognizer;
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
    [WLToast showWithMessage:@"This candy is no longer avaliable."];
    NSMutableOrderedSet* candies = self.historyItem.entries;
    [candies removeObject:candy];
    if (candies.nonempty) {
        [self.collectionView reloadData];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)notifier:(WLEntryNotifier *)notifier commentAdded:(WLComment *)comment {
    run_after(0.1,^{
        [self.candyCell.collectionView setMaximumContentOffsetAnimated:YES];
    });
}

- (WLCandy *)notifierPreferredCandy:(WLEntryNotifier *)notifier {
    return self.candy;
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
    WLCandy* candy = self.candy;
    if (candy.valid && candy.wrap.valid) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (IBAction)report:(UIButton *)sender {
    WLCandyOptionsViewController* editCandyViewController = [[WLCandyOptionsViewController alloc] init];
    editCandyViewController.entry = self.candy;
    [self presentViewController:editCandyViewController animated:YES completion:nil];
}

- (void)sendMessageWithText:(NSString*)text {
    [WLSoundPlayer playSound:WLSound_s04];
    [self.candy uploadComment:text success:^(WLComment *comment) {
    } failure:^(NSError *error) {
    }];
}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[self sendMessageWithText:text];
}

- (void)composeBarDidChangeHeight:(WLComposeBar *)composeBar {
    [self.candyCell updateBottomInset:[WLKeyboard keyboard].height + composeBar.height];
    [self.candyCell.collectionView setMaximumContentOffsetAnimated:YES];
}

- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar *)composeBar {
	return NO;
}

#pragma mark - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.historyItem.entries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLCommentsCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:WLCommentsCellIdentifier forIndexPath:indexPath];
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

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5f];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5f];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refresh) object:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    for (WLCommentsCell* cell in [self.collectionView visibleCells]) {
        CGFloat alpha = (cell.width - ABS(cell.x - scrollView.contentOffset.x)) / cell.width;
        cell.collectionView.alpha = cell.nameLabel.alpha = alpha;
    }
}

#pragma mark - WLNetworkReceiver

- (void)networkDidChangeReachability:(WLNetwork *)network {
    [self.candyCell.collectionView reloadData];
}

#pragma mark - WLKeyboardBroadcastReceiver

- (void)keyboardWillShow:(WLKeyboard *)keyboard {
    [super keyboardWillShow:keyboard];
    [self.candyCell updateBottomInset:keyboard.height + self.composeBarView.height];
    [self.candyCell.collectionView setMaximumContentOffsetAnimated:YES];
}

- (void)keyboardWillHide:(WLKeyboard *)broadcaster {
    [super keyboardWillHide:broadcaster];
    [self.candyCell updateBottomInset:self.composeBarView.height];
}

@end

