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
#import "WLActionViewController.h"
#import "WLCandiesRequest.h"
#import "WLCandy.h"
#import "WLCandyViewController.h"
#import "WLComment.h"
#import "WLCommentCell.h"
#import "WLCommentsCell.h"
#import "WLComposeBar.h"
#import "WLGroupedSet.h"
#import "WLImageFetcher.h"
#import "WLImageViewController.h"
#import "WLNetwork.h"
#import "WLKeyboard.h"
#import "WLNavigation.h"
#import "WLRefresher.h"
#import "WLReportCandyViewController.h"
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

@property (weak, nonatomic) IBOutlet UIButton *reportButton;
@property (weak, nonatomic) IBOutlet UIImageView *rightArrow;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBarView;
@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;

@property (nonatomic) BOOL shouldLoadMoreCandies;
@property (nonatomic) BOOL scrolledToInitialItem;
@property (strong, nonatomic) WLToast* dateChangeToast;

@property (readonly, nonatomic) WLCommentsCell* candyCell;

@property (weak, nonatomic) UISwipeGestureRecognizer* leftSwipeGestureRecognizer;
@property (weak, nonatomic) UISwipeGestureRecognizer* rightSwipeGestureRecognizer;


@end

@implementation WLCandyViewController

@synthesize candy = _candy;

- (void)viewDidLoad {
    [super viewDidLoad];
        
    if (!self.groups) {
        self.groups = [[WLGroupedSet alloc] init];
        [self.groups addEntries:[_candy.wrap candies]];
        _group = [self.groups groupWithCandy:_candy];
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
    NSUInteger index = [self.group.entries indexOfObject:_candy];
    if (!self.scrolledToInitialItem && index != NSNotFound) {
        [self.collectionView setContentOffset:CGPointMake(index*self.collectionView.width, 0)];
    }
}

- (void)setGroup:(WLGroup *)group {
    _group = group;
    [self.collectionView reloadData];
}

- (WLCandy *)candy {
    WLCommentsCell* cell = self.candyCell;
    if (cell) {
        return cell.entry;
    }
    NSUInteger index = floorf(self.collectionView.contentOffset.x/self.collectionView.width);
    return [self.group.entries tryObjectAtIndex:index];
}

- (WLCommentsCell *)candyCell {
    WLCommentsCell* candyCell = [[self.collectionView visibleCells] lastObject];
    return candyCell;
}

- (void)fetchOlder:(WLCandy*)candy {
    WLGroup *group = self.group;
    if (group.completed || !candy) return;
    NSUInteger count = [group.entries count];
    NSUInteger index = [group.entries indexOfObject:candy];
    BOOL shouldAppendCandies = (count >= 3) ? index > count - 3 : YES;
    if (shouldAppendCandies) {
        __weak typeof(self)weakSelf = self;
        [group older:^(NSOrderedSet *candies) {
            if (candies.nonempty) [weakSelf.collectionView reloadData];
        } failure:^(NSError *error) {
            if (error.isNetworkError) {
                group.completed = YES;
            }
        }];
    }
}

- (void)didSwipeLeft {
    if (self.group.completed) {
        NSUInteger (^increment)(NSUInteger index) = ^NSUInteger (NSUInteger index) {
            return index + 1;
        };
        if ([self swipeToGroupAtIndex:increment([self.groups.entries indexOfObject:self.group]) operationBlock:increment]) {
            [self.collectionView leftPush];
            [self onDateChanged];
        }
    } else {
        [self fetchOlder:self.candy];
    }
}

- (void)didSwipeRight {
    NSUInteger (^decrement)(NSUInteger index) = ^NSUInteger (NSUInteger index) {
        return index - 1;
    };
    if ([self swipeToGroupAtIndex:decrement([self.groups.entries indexOfObject:self.group]) operationBlock:decrement]) {
        [self.collectionView rightPush];
        [self onDateChanged];
    }
}

- (WLToast *)dateChangeToast {
    if (!_dateChangeToast) {
        _dateChangeToast = [[WLToast alloc] init];
    }
    return _dateChangeToast;
}

- (void)onDateChanged {
    WLToastAppearance* appearance = [WLToastAppearance appearance];
    appearance.shouldShowIcon = NO;
    appearance.height = 44;
    appearance.contentMode = UIViewContentModeCenter;
    appearance.backgroundColor = [UIColor colorWithRed:0.953 green:0.459 blue:0.149 alpha:0.75];
	appearance.endY = 64;
    appearance.startY = 64;
    [self.dateChangeToast showWithMessage:[self.group.date string] appearance:appearance inView:self.view];
    __weak typeof(self)weakSelf = self;
    self.rightArrow.hidden = NO;
    [UIView animateWithDuration:0.25f delay:1.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        weakSelf.rightArrow.alpha = 0.0f;
        weakSelf.rightArrow.transform = CGAffineTransformMakeTranslation(44, 0);
    } completion:^(BOOL finished) {
        weakSelf.rightArrow.hidden = YES;
        weakSelf.rightArrow.alpha = 1.0f;
        weakSelf.rightArrow.transform = CGAffineTransformIdentity;
    }];
}

- (BOOL)swipeToGroupAtIndex:(NSUInteger)index operationBlock:(NSUInteger (^)(NSUInteger index))operationBlock {
    if ([self.groups.entries containsIndex:index]) {
        WLGroup* group = [self.groups.entries objectAtIndex:index];
        self.group = group;
        self.collectionView.contentOffset = CGPointZero;
        return YES;
    }
    return NO;
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
    NSMutableOrderedSet* candies = self.group.entries;
    [candies removeObject:candy];
    if (candies.nonempty) {
        [self.collectionView reloadData];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)notifier:(WLEntryNotifier *)notifier commentAdded:(WLComment *)comment {
    run_after(0.1,^{
        [self.candyCell.collectionView scrollToBottomAnimated:YES];
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
    [WLActionViewController addViewControllerByClass:[WLReportCandyViewController class]
                                                     withEntry:self.candy
                                        toParentViewController:self];
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
    [self.candyCell.collectionView scrollToBottomAnimated:YES];
}

- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar *)composeBar {
	return NO;
}

#pragma mark - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.group.entries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLCommentsCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:WLCommentsCellIdentifier forIndexPath:indexPath];
    WLCandy* candy = [self.group.entries tryObjectAtIndex:indexPath.item];
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
    for (UICollectionViewCell* cell in [self.collectionView visibleCells]) {
        cell.alpha = (cell.frame.size.width - ABS(cell.x - scrollView.contentOffset.x)) / cell.frame.size.width;
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
    [self.candyCell.collectionView scrollToBottomAnimated:YES];
}

- (void)keyboardWillHide:(WLKeyboard *)broadcaster {
    [super keyboardWillHide:broadcaster];
    [self.candyCell updateBottomInset:self.composeBarView.height];
}

@end

