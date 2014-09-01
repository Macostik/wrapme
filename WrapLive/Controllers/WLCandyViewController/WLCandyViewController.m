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
#import "WLComposeBar.h"
#import "WLComposeContainer.h"
#import "WLGroupedSet.h"
#import "WLImageFetcher.h"
#import "WLImageViewController.h"
#import "WLKeyboardBroadcaster.h"
#import "WLNavigation.h"
#import "WLClearProgressBar.h"
#import "WLRefresher.h"
#import "WLSession.h"
#import "WLToast.h"
#import "WLUser.h"
#import "WLWrap.h"
#import "WLWrapBroadcaster.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "WLWrap+Extended.h"
#import "WLDetailedCandyCell.h"
#import "UIView+AnimationHelper.h"

@interface WLCandyViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, WLComposeBarDelegate, WLKeyboardBroadcastReceiver, WLWrapBroadcastReceiver, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *reportButton;
@property (weak, nonatomic) IBOutlet UIImageView *leftArrow;
@property (weak, nonatomic) IBOutlet UIImageView *rightArrow;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBarView;
@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;

@property (nonatomic) BOOL autoenqueueUploading;
@property (nonatomic) BOOL shouldLoadMoreCandies;
@property (strong, nonatomic) WLToast* dateChangeToast;

@property (readonly, nonatomic) WLDetailedCandyCell* candyCell;

@property (weak, nonatomic) UISwipeGestureRecognizer* leftSwipeGestureRecognizer;
@property (weak, nonatomic) UISwipeGestureRecognizer* rightSwipeGestureRecognizer;
@property (weak, nonatomic) IBOutlet UIView *navigationBar;

@end

@implementation WLCandyViewController

@synthesize candy = _candy;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    if (!self.groups) {
        self.groups = [WLGroupedSet groupsOrderedBy:self.orderBy];
        [self.groups addCandies:[_candy.wrap images]];
        self.group = [self.groups groupWithCandy:_candy];
    }
    
	self.composeBarView.placeholder = @"Write your comment ...";
	
	[[WLKeyboardBroadcaster broadcaster] addReceiver:self];
	
	[[WLWrapBroadcaster broadcaster] addReceiver:self];

    [self.collectionView reloadData];
    if (_candy && [self.group.entries containsObject:_candy]) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[self.group.entries indexOfObject:_candy] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.collectionView.height - 70, 0);
    
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.collectionView.height - 70, 0);
}

- (void)setGroup:(WLGroup *)group {
    _group = group;
    [self.collectionView reloadData];
}

- (void)setCandy:(WLCandy *)candy {
    _candy = candy;
    if (self.isViewLoaded && [self.group.entries containsObject:candy]) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[self.group.entries indexOfObject:candy] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

- (WLCandy *)candy {
    WLDetailedCandyCell* cell = self.candyCell;
    if (cell) {
        return cell.item;
    }
    NSUInteger index = floorf(self.collectionView.contentOffset.x/self.collectionView.width);
    return [self.group.entries tryObjectAtIndex:index];
}

- (WLDetailedCandyCell *)candyCell {
    return [[self.collectionView visibleCells] lastObject];
}

- (void)fetchNewer {
    WLCandy* candy = self.candy;
    if (!self.group.request.loading && [self.group.entries indexOfObject:candy] < 3) {
        self.group.request.type = WLPaginatedRequestTypeNewer;
        [self fetchCandies];
    }
}

- (void)fetchOlder:(WLCandy*)candy {
    if (self.group.completed) return;
    NSUInteger count = [self.group.entries count];
    NSUInteger index = [self.group.entries indexOfObject:candy];
    BOOL shouldAppendCandies = (count >= 3) ? index > count - 3 : YES;
    if (!self.group.request.loading && shouldAppendCandies) {
        self.group.request.type = WLPaginatedRequestTypeOlder;
        [self fetchCandies];
    }
}

- (void)fetchCandies {
    __weak typeof(self)weakSelf = self;
    [self.group send:^(NSOrderedSet *candies) {
        if (candies.nonempty) {
            [weakSelf.collectionView reloadData];
        }
    } failure:^(NSError *error) {
        if (error.isNetworkError) {
            weakSelf.group.completed = YES;
        }
    }];
}

- (void)didSwipeLeft {
    if (self.group.completed) {
        NSUInteger (^increment)(NSUInteger index) = ^NSUInteger (NSUInteger index) {
            return index + 1;
        };
        if ([self swipeToGroupAtIndex:increment([self.groups.set indexOfObject:self.group]) operationBlock:increment]) {
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
    if ([self swipeToGroupAtIndex:decrement([self.groups.set indexOfObject:self.group]) operationBlock:decrement]) {
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
    [self.dateChangeToast showWithMessage:self.group.name appearance:appearance inView:self.view];
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
    if ([self.groups.set containsIndex:index]) {
        WLGroup* group = [self.groups.set objectAtIndex:index];
        if ([group hasAtLeastOneImage]) {
            self.group = group;
            self.collectionView.contentOffset = CGPointZero;
            return YES;
        } else {
            return [self swipeToGroupAtIndex:operationBlock(index) operationBlock:operationBlock];
        }
    }
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isImageSegue]) {
		[self.composeBarView resignFirstResponder];
		WLImageViewController* controller = segue.destinationViewController;
		controller.image = self.candy;
	}
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

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyChanged:(WLCandy *)candy {
    [self.collectionView reloadData];
    if (self.autoenqueueUploading) {
        self.autoenqueueUploading = NO;
        for (WLComment* comment in candy.comments) {
            if (!comment.uploaded) {
                [WLUploading enqueueAutomaticUploading:^{
                }];
                break;
            }
        }
    }
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster commentRemoved:(WLComment *)comment {
	[self.collectionView reloadData];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyRemoved:(WLCandy *)candy {
    [WLToast showWithMessage:@"This candy is no longer avaliable."];
    NSMutableOrderedSet* candies = self.group.entries;
    [candies removeObject:candy];
    if (candies.nonempty) {
        [self.collectionView reloadData];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (WLWrap *)broadcasterPreferedWrap:(WLWrapBroadcaster *)broadcaster {
    return self.candy.wrap;
}

- (WLCandy *)broadcasterPreferedCandy:(WLWrapBroadcaster *)broadcaster {
    return self.candy;
}

#pragma mark - WLKeyboardBroadcastReceiver

- (void)broadcasterWillHideKeyboard:(WLKeyboardBroadcaster *)broadcaster {
    self.composeBarView.y = self.view.height - self.composeBarView.height;
	self.collectionView.transform = CGAffineTransformIdentity;
    [self.collectionView reloadData];
    self.navigationBar.y = 0;
}

- (void)broadcaster:(WLKeyboardBroadcaster *)broadcaster willShowKeyboardWithHeight:(NSNumber*)keyboardHeight {
    self.composeBarView.y = self.view.height - [keyboardHeight floatValue] - self.composeBarView.height;
	self.collectionView.transform = CGAffineTransformMakeTranslation(0, -[keyboardHeight floatValue]);
    __weak typeof(self)weakSelf = self;
    [self.collectionView reloadData];
    run_after(0.0f, ^{
        [weakSelf.candyCell.tableView scrollToBottomAnimated:YES];
    });
    self.navigationBar.y = -self.navigationBar.height;
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
    WLCandy* candy = self.candy;
    if ([candy.contributor isCurrentUser] || [candy.wrap.contributor isCurrentUser]) {
        [UIActionSheet showWithTitle:nil cancel:@"Cancel" destructive:@"Delete" completion:^(NSUInteger index) {
            if (index == 0) {
                [candy remove:^(id object) {
                    [WLToast showWithMessage:@"Candy was deleted successfully."];
                } failure:^(NSError *error) {
                    [error show];
                }];
            }
        }];
    } else {
        [UIActionSheet showWithTitle:nil cancel:@"Cancel" destructive:@"Report as inappropriate" completion:^(NSUInteger index) {
            if (index == 0) {
                [MFMailComposeViewController messageWithCandy:candy];
            }
        }];
    }
}

- (void)sendMessageWithText:(NSString*)text {
    WLCandy* image = self.candy;
    self.autoenqueueUploading = !image.uploaded;
	__weak typeof(self)weakSelf = self;
    [image uploadComment:text success:^(WLComment *comment) {
        [weakSelf.candyCell reloadComments];
    } failure:^(NSError *error) {
    }];
    [self.candyCell.tableView scrollToBottomAnimated:YES];
}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
	[self sendMessageWithText:text];
}

- (void)composeBarHeightDidChanged:(WLComposeBar *)composeBar {
	composeBar.y = self.view.height - [[WLKeyboardBroadcaster broadcaster].keyboardHeight floatValue] - composeBar.height;
    __weak typeof(self)weakSelf = self;
    [self.collectionView reloadData];
    run_after(0.0f, ^{
        [weakSelf.candyCell.tableView scrollToBottomAnimated:YES];
    });
}

- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar *)composeBar {
	return YES;
}

#pragma mark - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.group.entries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLDetailedCandyCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:WLDetailedCandyCellIdentifier forIndexPath:indexPath];
    cell.item = [self.group.entries tryObjectAtIndex:indexPath.item];
    [self fetchOlder:cell.item];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return collectionView.size;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self refresh];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self refresh];
    }
}

@end
