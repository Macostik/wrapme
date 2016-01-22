//
//  WLHistoryViewController.m
//  meWrap
//
//  Created by Ravenpod on 5/7/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLHistoryViewController.h"
#import "WLButton.h"
#import "WLTextView.h"
#import "WLLabel.h"
#import "WLHintView.h"
#import "WLCandyViewController.h"
#import "WLCommentsViewController.h"
#import "WLDrawingViewController.h"
#import "WLImageEditorSession.h"
#import "NSArray+WLCollection.h"

@interface WLHistoryViewController () <EntryNotifying>
@property (weak, nonatomic) IBOutlet LayoutPrioritizer *bottomViewHeightPrioritizer;
@property (weak, nonatomic) IBOutlet LayoutPrioritizer *primaryConstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIButton *drawButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *reportButton;
@property (weak, nonatomic) IBOutlet HistoryFooterView *bottomView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet WLButton *commentButton;

@property (nonatomic) BOOL disableRotation;
@property (strong, nonatomic) NSIndexPath *candyIndex;
@property (strong, nonatomic) NSMapTable *cachedCandyViewControllers;
@property (weak, nonatomic) Candy *removedCandy;
@property (strong, nonatomic) RunQueue *paginationQueue;

@property (weak, nonatomic) Wrap *wrap;

@property (strong, nonatomic) History *history;

@end

@implementation WLHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.contentView addGestureRecognizer:self.scrollView.panGestureRecognizer];
    
    self.paginationQueue = [[RunQueue alloc] initWithLimit:1];
    
    self.wrap = _candy.wrap;
    
    [[Candy notifier] addReceiver:self];
    
    self.commentButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    if (self.historyItem == nil) {
        self.history = [[History alloc] initWithWrap:self.wrap];
        for (HistoryItem *item in self.history.entries) {
            if ([item.candies containsObject:self.candy]) {
                self.historyItem = item;
                break;
            }
        }
    } else {
        self.history = self.historyItem.history;
    }

    [self setCandy:_candy direction:0 animated:NO];
    
    [UIView performWithoutAnimation:^{
        [UIViewController attemptRotationToDeviceOrientation];
    }];
    
    if (self.showCommentViewController) {
        [self showCommentView];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.bottomView.comment = nil;
    [self updateOwnerData];
    if (!self.showCommentViewController) {
        [self setBarsHidden:NO animated:animated];
        self.commentButtonPrioritizer.defaultState = YES;
    }
    if (!_candy.valid) {
        Candy *nextCandy = [self candyAfterDeletingCandy:_candy];
        if (nextCandy) {
            [self setCandy:nextCandy direction:0 animated:NO];
        } else {
            [self.navigationController popViewControllerAnimated:NO];
        }
    }
}

- (void)showCommentView {
    [self.commentButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    self.showCommentViewController = NO;
}

- (void)setBarsHidden:(BOOL)hidden animated:(BOOL)animated {
    [self.primaryConstraint setDefaultState:!hidden animated:animated];
}

- (void)setCandy:(Candy *)candy direction:(WLSwipeViewControllerDirection)direction animated:(BOOL)animated {
    _candy = candy;
    WLCandyViewController *candyViewController = [self candyViewController:candy];
    [self updateOwnerData];
    [self setViewController:candyViewController direction:direction animated:animated];
}

- (void)fetchCandiesOlderThen:(Candy *)candy {
    PaginatedList *candies = self.history;
    NSUInteger index = [self.historyItem.candies indexOfObject:candy];
    BOOL shouldFetch = index != NSNotFound && self.history.entries.lastObject == self.historyItem && (candies.entries.count - index) < 4;
    if (!candies.completed && candy && shouldFetch) {
        __weak typeof(self)weakSelf = self;
        [self.paginationQueue run:^(Block finish) {
            [weakSelf.spinner startAnimating];
            [candies older:^(NSArray *candies) {
                [weakSelf.spinner stopAnimating];
                finish();
            } failure:^(NSError *error) {
                [weakSelf.spinner stopAnimating];
                finish();
            }];
        }];
    }
}

- (void)setCandy:(Candy *)candy {
    if (candy != _candy) {
        _candy = candy.valid ? candy : nil;
        if (self.isViewLoaded) [self updateOwnerData];
    }
}

- (void)updateOwnerData {
    Candy *candy = _candy;
    self.bottomView.candy = candy;
    [self setCommentButtonTitle:candy];
    self.deleteButton.hidden = !candy.deletable;
    self.reportButton.hidden = !self.deleteButton.hidden;
    self.drawButton.hidden = self.editButton.hidden = candy.isVideo;
    self.bottomViewHeightPrioritizer.defaultState = self.candy.latestComment.valid;
}

- (void)setCommentButtonTitle:(Candy *)candy {
    NSString *title = @"comment".ls;
    if (candy.commentCount == 1) {
        title = @"one_comment".ls;
    } else if (candy.commentCount > 1){
        title = [NSString stringWithFormat:@"formatted_comments".ls, (int)candy.commentCount];
    }
    [self.commentButton setTitle:title forState:UIControlStateNormal];
}

// MARK: - EntryNotifying

- (Candy *)candyAfterDeletingCandy:(Candy *)candy {
    
    if (!self.wrap.candies.nonempty) {
        return nil;
    }
    
    candy = [self.historyItem.candies tryAt:self.candyIndex.item];
    if (candy) {
        return candy;
    }
    
    HistoryItem *nextItem = nil;
    if ([self.history.entries containsObject:self.historyItem]) {
        nextItem = [self.history.entries tryAt:[self.history.entries indexOfObject:self.historyItem] - 1];
    } else {
        nextItem = [self.history.entries tryAt:self.candyIndex.section];
    }
    if (nextItem) {
        self.historyItem = nextItem;
        return [nextItem.candies lastObject];
    }
    
    candy = [self.historyItem.candies tryAt:self.candyIndex.item - 1];
    if (candy) {
        return candy;
    }
    
    HistoryItem *previousItem = nil;
    if ([self.history.entries containsObject:self.historyItem]) {
        previousItem = [self.history.entries tryAt:[self.history.entries indexOfObject:self.historyItem] + 1];
    } else {
        previousItem = [self.history.entries tryAt:self.candyIndex.section + 1];
    }
    if (previousItem) {
        self.historyItem = previousItem;
        return [previousItem.candies firstObject];
    }
    
    return [self.historyItem.candies firstObject];
}

- (void)notifier:(EntryNotifier *)notifier didAddEntry:(Candy *)candy {
    self.candyIndex = [NSIndexPath indexPathForItem:[self.historyItem.candies indexOfObject:self.candy] inSection:[self.history.entries indexOfObject:self.historyItem]];
}

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(Candy *)candy event:(enum EntryUpdateEvent)event {
    if (candy == self.candy) {
        [self updateOwnerData];
    }
}

- (void)notifier:(EntryNotifier *)notifier willDeleteEntry:(Candy *)candy {
    if (candy == self.candy) {
        if (self.navigationController.presentedViewController) {
            [self.navigationController dismissViewControllerAnimated:NO completion:nil];
        }
        if (self.removedCandy == candy) {
            [Toast show:(candy.isVideo ? @"video_deleted" : @"photo_deleted").ls];
            self.removedCandy = nil;
        } else {
            [Toast show:(candy.isVideo ? @"video_unavailable" : @"photo_unavailable").ls];
        }
        Candy *nextCandy = [self candyAfterDeletingCandy:candy];
        if (nextCandy) {
            [self setCandy:nextCandy direction:0 animated:NO];
            [self setBarsHidden:NO animated:YES];
        } else {
            [self.navigationController popViewControllerAnimated:NO];
        }
    }
    [self removedCachedViewControllerForCandy:candy];
}

- (void)notifier:(EntryNotifier *)notifier willDeleteContainer:(Wrap *)wrap {
    [Toast showMessageForUnavailableWrap:wrap];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return entry.container == self.wrap;
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnContainer:(Entry *)entry {
    return self.wrap == entry;
}

// MARK: - Actions

- (IBAction)back:(id)sender {
    BOOL animate = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    Candy *candy = self.candy;
    if (candy.valid) {
        if (self.presenter != nil && animate) {
            [self.navigationController popViewControllerAnimated:NO];
            [self.presenter dismiss:candy];
        } else {
            [self.navigationController popViewControllerAnimated:animate];
        }
    } else {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
    
}

- (IBAction)downloadCandy:(WLButton*)sender {
    __weak typeof(self)weakSelf = self;
    [FollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        sender.loading = YES;
        [weakSelf.candy download:^{
            sender.loading = NO;
            [Toast showDownloadingMediaMessageForCandy:weakSelf.candy];
        } failure:^(NSError *error) {
            if (error.isNetworkError) {
                [Toast show:@"downloading_internet_connection_error".ls];
            } else {
                [error show];
            }
            sender.loading = NO;
        }];
    }];
}

- (IBAction)deleteCandy:(WLButton *)sender {
    __weak typeof(self)weakSelf = self;
    [FollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        Candy *candy = weakSelf.candy;
        [UIAlertController confirmCandyDeleting:candy success:^(UIAlertAction *action) {
            weakSelf.removedCandy = candy;
            sender.loading = YES;
            [candy delete:^(id object) {
                sender.loading = NO;
            } failure:^(NSError *error) {
                weakSelf.removedCandy = nil;
                [error show];
                sender.loading = NO;
            }];
        } failure:nil];
    }];
}

- (IBAction)report:(id)sender {
    ReportViewController *controller = (id)self.storyboard[@"report"];
    controller.candy = self.candy;
    [self.navigationController presentViewController:controller animated:NO completion:nil];
}

- (IBAction)editPhoto:(id)sender {
    __weak typeof(self)weakSelf = self;
    [FollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        __weak Candy *candy = weakSelf.candy;
        [weakSelf downloadCandyOriginal:candy success:^(UIImage *image) {
            [WLImageEditorSession editImage:image completion:^(UIImage *image) {
                [candy editWithImage:image];
            } cancel:nil];
        } failure:^(NSError *error) {
            [error show];
        }];
    }];
}

- (IBAction)draw:(UIButton *)sender {
    __weak __typeof(self)weakSelf = self;
    sender.userInteractionEnabled = NO;
    [FollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        __weak Candy *candy = weakSelf.candy;
        [weakSelf downloadCandyOriginal:candy success:^(UIImage *image) {
            [WLDrawingViewController draw:image finish:^(UIImage *image) {
                [candy editWithImage:image];
            }];
            sender.userInteractionEnabled = YES;
        } failure:^(NSError *error) {
            [error show];
            sender.userInteractionEnabled = YES;
        }];
    }];
}

- (IBAction)comments:(id)sender {
    if (self.commentPressed) {
        self.commentPressed();
    }
    __weak typeof(self)weakSelf = self;
    [FollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        for (UIViewController *controller in [self childViewControllers]) {
            if ([controller isKindOfClass:WLCommentsViewController.class]) {
                return;
            }
        }
        [weakSelf setBarsHidden:YES animated:YES];
        [self applyScaleToCandyViewController:YES];
        WLCommentsViewController *controller = (id)weakSelf.storyboard[@"WLCommentsViewController"];
        controller.candy = weakSelf.candy;
        [controller presentForController:weakSelf animated:YES];
    }];
}

- (void)downloadCandyOriginal:(Candy *)candy success:(ImageBlock)success failure:(FailureBlock)failure {
    if (candy) {
        NSError *error = [candy updateError];
        if (error) {
            if (failure) failure(error);
        } else {
            [DownloadingView downloadCandy:candy success:success failure:failure];
        }
    } else {
        if (failure) failure(nil);
    }
}

- (IBAction)hadleTapRecognizer:(id)sender {
    [self setBarsHidden:self.primaryConstraint.defaultState animated:YES];
    self.commentButtonPrioritizer.defaultState = self.primaryConstraint.defaultState;
}

// MARK: - WLSwipeViewController Methods

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.cachedCandyViewControllers removeAllObjects];
}

- (WLCandyViewController *)candyViewController:(Candy *)candy {
    if (!self.cachedCandyViewControllers) {
        self.cachedCandyViewControllers = [NSMapTable weakToStrongObjectsMapTable];
    }
    WLCandyViewController *candyViewController = [self.cachedCandyViewControllers objectForKey:candy];
    if (!candyViewController) {
        candyViewController = (id)self.storyboard[@"WLCandyViewController"];
        candyViewController.candy = candy;
        [self.cachedCandyViewControllers setObject:candyViewController forKey:candy];
    }
    candyViewController.historyViewController = self;

    return candyViewController;
}

- (void)removedCachedViewControllerForCandy:(Candy *)candy {
    WLCandyViewController *candyViewController = [self.cachedCandyViewControllers objectForKey:candy];
    if (candyViewController) {
        [self.cachedCandyViewControllers removeObjectForKey:candy];
    }
}

- (UIViewController *)viewControllerAfterViewController:(WLCandyViewController *)viewController {
    Candy *candy = viewController.candy;
    HistoryItem *item = self.historyItem;
    candy = [item.candies tryAt:[item.candies indexOfObject:candy] + 1];
    if (candy) {
        return [self candyViewController:candy];
    }
    
    item = [self.history.entries tryAt:[self.history.entries indexOfObject:item] - 1];
    if (item) {
        self.historyItem = item;
        return [self candyViewController:[item.candies firstObject]];
    }
    
    [self fetchCandiesOlderThen:self.candy];
    
    return nil;
}

- (UIViewController *)viewControllerBeforeViewController:(WLCandyViewController *)viewController {
    Candy *candy = viewController.candy;
    HistoryItem *item = self.historyItem;
    candy = [item.candies tryAt:[item.candies indexOfObject:candy] - 1];
    if (candy) {
        return [self candyViewController:candy];
    } else {
        item = [self.history.entries tryAt:[self.history.entries indexOfObject:item] + 1];
        if (item) {
            self.historyItem = item;
            return [self candyViewController:[item.candies lastObject]];
        }
    }
    return nil;
}

- (void)didChangeViewController:(WLCandyViewController *)viewController {
    self.candy = [viewController candy];
    self.candyIndex = [NSIndexPath indexPathForItem:[self.historyItem.candies indexOfObject:self.candy] inSection:[self.history.entries indexOfObject:self.historyItem]];
    [self fetchCandiesOlderThen:self.candy];
}

- (void)didChangeOffsetForViewController:(UIViewController *)viewController offset:(CGFloat)offset {
    viewController.view.alpha = offset;
}

// MARK: - DeviceManagerNotifying

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.disableRotation ? [super supportedInterfaceOrientations] : UIInterfaceOrientationMaskAll;
}

// MARK: - CommentViewControllerDelegate

- (void)applyScaleToCandyViewController:(BOOL)apply {
    WLCandyViewController *candyViewController = [self candyViewController:self.candy];
    [UIView animateWithDuration:.25 animations:^{
        candyViewController.view.transform = apply ? CGAffineTransformMakeScale(0.9, 0.9) : CGAffineTransformIdentity;
    }];
    [self setBarsHidden:apply animated:YES];
}

- (void)hideSecondaryViews:(BOOL)hide {
    self.bottomView.hidden = hide;
    self.topView.hidden = hide;
    self.commentButton.hidden = hide;
    if (hide) {
        [self.bottomView addAnimation:[CATransition transition:kCATransitionFade]];
        [self.topView addAnimation:[CATransition transition:kCATransitionFade]];
        [self.commentButton addAnimation:[CATransition transition:kCATransitionFade]];
    }
}

@end
