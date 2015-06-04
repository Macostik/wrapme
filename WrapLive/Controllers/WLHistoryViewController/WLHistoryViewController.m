//
//  WLHistoryViewController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 5/7/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLHistoryViewController.h"
#import "WLButton.h"
#import "WLTextView.h"
#import "WLLabel.h"
#import "WLIconButton.h"
#import "WLEntryStatusIndicator.h"
#import "WLHintView.h"
#import "UIView+AnimationHelper.h"
#import "UITextView+Aditions.h"
#import "WLToast.h"
#import "MFMailComposeViewController+Additions.h"
#import "WLCandyViewController.h"
#import "WLNavigationHelper.h"
#import "WLDownloadingView.h"
#import "WLImageCache.h"
#import "WLUploadPhotoViewController.h"
#import "WLPresentingImageView.h"

static NSTimeInterval WLHistoryBottomViewModeTogglingInterval = 4;

typedef NS_ENUM(NSUInteger, WLHistoryBottomViewMode) {
    WLHistoryBottomViewModeCreating,
    WLHistoryBottomViewModeEditing
};

@interface WLHistoryViewController ()

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet WLButton *commentButton;
@property (weak, nonatomic) IBOutlet WLIconButton *actionButton;
@property (weak, nonatomic) IBOutlet WLIconButton *editButton;
@property (weak, nonatomic) IBOutlet WLLabel *postLabel;
@property (weak, nonatomic) IBOutlet WLLabel *timeLabel;
@property (weak, nonatomic) IBOutlet WLEntryStatusIndicator *commentIndicator;
@property (weak, nonatomic) IBOutlet WLEntryStatusIndicator *candyIndicator;

@property (weak, nonatomic) WLComment *lastComment;

@property (weak, nonatomic) IBOutlet WLImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet WLTextView *lastCommentTextView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewContstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) NSMapTable *cachedCandyViewControllers;
@property (strong, nonatomic) WLUploadPhotoCompletionBlock completionBlock;

@property (nonatomic) NSUInteger currentCandyIndex;

@property (nonatomic) NSUInteger currentHistoryItemIndex;

@property (weak, nonatomic) WLCandy* removedCandy;

@property (nonatomic) WLHistoryBottomViewMode bottomViewMode;

@end

@implementation WLHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lastCommentTextView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    self.lastCommentTextView.textContainer.maximumNumberOfLines = 2;
    self.lastCommentTextView.textContainerInset = UIEdgeInsetsZero;
    self.lastCommentTextView.textContainer.lineFragmentPadding = .0;
    [self.avatarImageView setImageName:@"default-medium-avatar" forState:WLImageViewStateFailed];
    [self.avatarImageView setImageName:@"default-medium-avatar" forState:WLImageViewStateEmpty];
    
    if (!_wrap) {
        _wrap = _candy.wrap;
    }
    
    if (!_history && _wrap) {
        _history = [WLHistory historyWithWrap:self.wrap];
    }
    
    if (!_historyItem) {
        if (_candy) {
            _historyItem = [self.history itemWithCandy:_candy];
        } else {
            _historyItem = [self.history.entries firstObject];
            _candy = [_historyItem.entries firstObject];
        }
    }

    [self addNotifyReceivers];
    
    self.commentButton.layer.borderColor = [UIColor whiteColor].CGColor;

    __weak typeof(self)weakSelf = self;
    WLOperationQueue *paginationQueue = [WLOperationQueue queueNamed:@"wl_candy_pagination_queue"];
    [paginationQueue setStartQueueBlock:^{
        [weakSelf.spinner startAnimating];
    }];
    [paginationQueue setFinishQueueBlock:^{
        [weakSelf.spinner stopAnimating];
    }];

    [self setCandy:_candy direction:0 animated:NO];
    
    [UIView performWithoutAnimation:^{
        [UIViewController attemptRotationToDeviceOrientation];
    }];
}

- (void)toggleBottomViewMode {
    if (self.bottomViewMode == WLHistoryBottomViewModeCreating) {
        self.bottomViewMode = WLHistoryBottomViewModeEditing;
    } else {
        self.bottomViewMode = WLHistoryBottomViewModeCreating;
    }
    [self performSelector:@selector(toggleBottomViewMode) withObject:nil afterDelay:WLHistoryBottomViewModeTogglingInterval inModes:@[NSRunLoopCommonModes]];
}

- (void)setBottomViewMode:(WLHistoryBottomViewMode)bottomViewMode {
    WLCandy *candy = _candy;
    if (_bottomViewMode != bottomViewMode && !(bottomViewMode == WLHistoryBottomViewModeEditing && candy.editor == nil)) {
        _bottomViewMode = bottomViewMode;
        CATransition *transition = [CATransition animation];
        transition.duration = 0.25f;
        transition.type = kCATransitionPush;
        transition.subtype = kCATransitionFromTop;
        [self.postLabel.superview.layer addAnimation:transition forKey:@"toggling"];
    }
    [self setupBottomViewModeRelatedData:_bottomViewMode candy:candy];
}

- (void)setupBottomViewModeRelatedData:(WLHistoryBottomViewMode)bottomViewMode candy:(WLCandy*)candy {
    if (bottomViewMode == WLHistoryBottomViewModeEditing && candy.editor != nil) {
        self.postLabel.text = [NSString stringWithFormat:WLLS(@"formatted_edited_by"), candy.editor.name];
        self.timeLabel.text = [candy.editedAt.timeAgoStringAtAMPM stringByCapitalizingFirstCharacter];
    } else {
        self.postLabel.text = [NSString stringWithFormat:WLLS(@"formatted_photo_by"), candy.contributor.name];
        self.timeLabel.text = [candy.createdAt.timeAgoStringAtAMPM stringByCapitalizingFirstCharacter];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.lastComment = nil;
    [self updateOwnerData];
    if (!self.showCommentViewController) {
        [self setBarsHidden:NO animated:animated];
    }
    if (_candy.invalid) {
        WLCandy *nextCandy = [self candyAfterDeletingCandy:_candy];
        if (nextCandy) {
            [self setCandy:nextCandy direction:0 animated:NO];
        } else {
            [self.navigationController popViewControllerAnimated:NO];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WLHintView showCandySwipeHintView];
    if (self.showCommentViewController) {
        [self showCommentView];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(toggleBottomViewMode) object:nil];
    [self performSelector:@selector(toggleBottomViewMode) withObject:nil afterDelay:WLHistoryBottomViewModeTogglingInterval inModes:@[NSRunLoopCommonModes]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(toggleBottomViewMode) object:nil];
}

- (void)showCommentView {
    [self.commentButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    self.showCommentViewController = NO;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIBezierPath *exlusionPath = [UIBezierPath bezierPathWithRect:[self.bottomView convertRect:self.commentIndicator.frame
                                                                                        toView:self.lastCommentTextView]];
    
    self.lastCommentTextView.textContainer.exclusionPaths = [self.lastComment.contributor isCurrentUser] ? @[exlusionPath] : nil;
}

- (IBAction)hideBars {
    [self setBarsHidden:YES animated:YES];
}

- (void)setBarsHidden:(BOOL)hidden animated:(BOOL)animated {
    __weak typeof(self)weakSelf = self;
    [UIView performAnimated:animated animation:^{
        weakSelf.topViewConstraint.constant = hidden ? -weakSelf.topView.height : .0f;
        weakSelf.bottomViewContstraint.constant = hidden ? -weakSelf.bottomView.height : .0f;
        [weakSelf.view setNeedsLayout];
    }];
}

- (void)setHistoryItem:(WLHistoryItem *)historyItem direction:(WLSwipeViewControllerDirection)direction animated:(BOOL)animated {
    _historyItem = historyItem;
    if (direction == WLSwipeViewControllerDirectionForward) {
        [self setCandy:[historyItem.entries firstObject] direction:direction animated:animated];
    } else {
        [self setCandy:[historyItem.entries lastObject] direction:direction animated:animated];
    }
}

- (void)setCandy:(WLCandy *)candy direction:(WLSwipeViewControllerDirection)direction animated:(BOOL)animated {
    _candy = candy;
    [self updateOwnerData];
    [self setViewController:[self candyViewController:candy] direction:direction animated:animated];
}

- (void)fetchCandiesOlderThen:(WLCandy*)candy {
    WLHistoryItem *historyItem = self.historyItem;
    if (historyItem.completed || historyItem.request.loading || !candy) return;
    NSUInteger count = [historyItem.entries count];
    NSUInteger index = [historyItem.entries indexOfObject:candy];
    BOOL shouldAppendCandies = (count >= 3) ? index > count - 3 : YES;
    if (shouldAppendCandies) {
        runUnaryQueuedOperation(@"wl_candy_pagination_queue", ^(WLOperation *operation) {
            [historyItem older:^(NSOrderedSet *candies) {
                [operation finish];
            } failure:^(NSError *error) {
                if (error.isNetworkError) {
                    historyItem.completed = YES;
                }
                [operation finish];
            }];
        });
    }
}

- (void)fetchHistoryItemsOlderThen:(WLHistoryItem*)historyItem {
    WLHistory *history = self.history;
    if (history.completed || history.request.loading || !historyItem) return;
    NSUInteger count = [history.entries count];
    NSUInteger index = [history.entries indexOfObject:historyItem];
    BOOL shouldAppendCandies = (count >= 3) ? index > count - 3 : YES;
    if (shouldAppendCandies) {
        runUnaryQueuedOperation(@"wl_candy_pagination_queue", ^(WLOperation *operation) {
            [history older:^(NSOrderedSet *candies) {
                [operation finish];
            } failure:^(NSError *error) {
                if (error.isNetworkError) {
                    historyItem.completed = YES;
                }
                [operation finish];
            }];
        });
    }
}

- (void)setCandy:(WLCandy *)candy {
    if (candy != _candy) {
        _candy = candy.valid ? candy : nil;
        if (self.isViewLoaded) [self updateOwnerData];
    }
}

- (void)setLastComment:(WLComment *)lastComment {
    if (lastComment != _lastComment) {
        _lastComment = lastComment;
        UITextView *textView = self.lastCommentTextView;
        self.avatarImageView.hidden = textView.hidden = self.self.commentIndicator.hidden = lastComment.text.length == 0;
        if (textView && !textView.hidden) {
            self.avatarImageView.url = lastComment.contributor.picture.small;
            [textView determineHyperLink:lastComment.text];
            [self.commentIndicator updateStatusIndicator:lastComment];
        }
    }
}

- (void)updateOwnerData {
    WLCandy *candy = _candy;
    [candy markAsRead];
    [self.candyIndicator updateStatusIndicator:candy];
    self.actionButton.iconName = candy.deletable ? @"trash" : @"warning";
    [self setCommentButtonTitle:candy];
    [self setupBottomViewModeRelatedData:self.bottomViewMode candy:candy];
    self.lastComment = [candy latestComment];
}

- (void)setCommentButtonTitle:(WLCandy *)candy {
    NSString *title = WLLS(@"comment");
    if (candy.commentCount == 1) {
        title = WLLS(@"one_comment");
    } else if (candy.commentCount > 1){
        title = [NSString stringWithFormat:WLLS(@"formatted_comments"), (int)candy.commentCount];
    }
    [self.commentButton setTitle:title forState:UIControlStateNormal];
}

#pragma mark - WLEntryNotifyReceiver

- (WLCandy*)candyAfterDeletingCandy:(WLCandy*)candy {
    
    if (!self.wrap.candies.nonempty) {
        return nil;
    }
    
    candy = [self.historyItem.entries tryObjectAtIndex:self.currentCandyIndex];
    if (candy) {
        return candy;
    }
    
    WLHistoryItem *nextItem = nil;
    if ([self.history.entries containsObject:self.historyItem]) {
        nextItem = [self.history.entries tryObjectAtIndex:[self.history.entries indexOfObject:self.historyItem] + 1];
    } else {
        nextItem = [self.history.entries tryObjectAtIndex:self.currentHistoryItemIndex];
    }
    if (nextItem) {
        self.historyItem = nextItem;
        return [nextItem.entries firstObject];
    }
    
    candy = [self.historyItem.entries tryObjectAtIndex:self.currentCandyIndex - 1];
    if (candy) {
        return candy;
    }
    
    WLHistoryItem *previousItem = nil;
    if ([self.history.entries containsObject:self.historyItem]) {
        previousItem = [self.history.entries tryObjectAtIndex:[self.history.entries indexOfObject:self.historyItem] - 1];
    } else {
        previousItem = [self.history.entries tryObjectAtIndex:self.currentHistoryItemIndex - 1];
    }
    if (previousItem) {
        self.historyItem = previousItem;
        return [previousItem.entries lastObject];
    }
    
    return [self.historyItem.entries firstObject];
}

- (void)addNotifyReceivers {
    __weak typeof(self)weakSelf = self;
    
    [WLCandy notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        
        [receiver setContainingEntryBlock:^WLEntry *{
            return weakSelf.wrap;
        }];
        
        [receiver setAddedBlock:^(WLCandy *candy) {
            weakSelf.currentCandyIndex = [weakSelf.historyItem.entries indexOfObject:weakSelf.candy];
            weakSelf.currentHistoryItemIndex = [weakSelf.history.entries indexOfObject:weakSelf.historyItem];
        }];
        
        [receiver setUpdatedBlock:^(WLCandy *candy) {
            if (candy == weakSelf.candy) {
                [weakSelf updateOwnerData];
            }
        }];
        
        [receiver setDeletedBlock:^(WLCandy *candy) {
            if (candy == weakSelf.candy) {
                if (weakSelf.navigationController.presentedViewController) {
                    [weakSelf.navigationController dismissViewControllerAnimated:NO completion:nil];
                }
                if (weakSelf.removedCandy == candy) {
                    [WLToast showWithMessage:WLLS(@"candy_deleted")];
                    weakSelf.removedCandy = nil;
                } else {
                    [WLToast showWithMessage:WLLS(@"candy_unavailable")];
                }
                WLCandy *nextCandy = [weakSelf candyAfterDeletingCandy:candy];
                if (nextCandy) {
                    [weakSelf setCandy:nextCandy direction:0 animated:NO];
                } else {
                    [weakSelf.navigationController popViewControllerAnimated:NO];
                }
            }
            [weakSelf removedCachedViewControllerForCandy:candy];
        }];
    }];
    
    [WLWrap notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setEntryBlock:^WLEntry *{
            return weakSelf.wrap;
        }];
        [receiver setDeletedBlock:^(WLWrap *wrap) {
            [WLToast showMessageForUnavailableWrap:wrap];
            [weakSelf.navigationController popToRootViewControllerAnimated:NO];
        }];
    }];
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
    BOOL animate = self.interfaceOrientation == UIInterfaceOrientationPortrait ||
    self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown;
    WLCandy* candy = self.candy;
    if (candy.valid) {
        if (self.presentingImageView != nil && animate) {
            [self.presentingImageView setImageUrl:_candy.picture.large];
            [self.navigationController popViewControllerAnimated:NO];
            [self.presentingImageView dismissViewByCandy:candy completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:animate];
        }
    } else {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
    
}

- (IBAction)downloadCandy:(id)sender {
    [self.candy download:^{
        [WLToast showPhotoDownloadingMessage];
    } failure:^(NSError *error) {
        [error show];
    }];
}

- (IBAction)navigationButtonClick:(WLIconButton *)sender {
    sender.userInteractionEnabled = NO;
    WLCandy *candy = self.candy;
    self.removedCandy = candy;
    if (candy.deletable) {
        __weak typeof(self)weakSelf = self;
        [candy remove:^(id object) {
            sender.userInteractionEnabled = YES;
        } failure:^(NSError *error) {
            weakSelf.removedCandy = nil;
            [error show];
            sender.userInteractionEnabled = YES;
        }];
    } else {
        [MFMailComposeViewController messageWithCandy:self.candy];
    }
}

- (IBAction)editPhoto:(id)sender {
    __weak __typeof(self)weakSelf = self;
    [self.candy prepareForUpdate:^(WLContribution *contribution, WLContributionStatus status) {
        [WLDownloadingView downloadAndEditCandy:weakSelf.candy success:^(UIImage *image) {
        } failure:^(NSError *error) {
            [error show];
        }];
    } failure:^(NSError *error) {
        [error show];
    }];
}

- (IBAction)toggleBottomViewMode:(id)sender {
    if ([self.postLabel.superview.layer animationKeys].count == 0) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(toggleBottomViewMode) object:nil];
        [self toggleBottomViewMode];
    }
}

#pragma mark - WLSwipeViewController Methods

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.cachedCandyViewControllers removeAllObjects];
}

- (WLCandyViewController *)candyViewController:(WLCandy*)candy {
    if (!self.cachedCandyViewControllers) {
        self.cachedCandyViewControllers = [NSMapTable weakToStrongObjectsMapTable];
        
    }
    WLCandyViewController *candyViewController = [self.cachedCandyViewControllers objectForKey:candy];
    if (!candyViewController) {
        candyViewController = [WLCandyViewController instantiate:self.storyboard];
        candyViewController.candy = candy;
        [self.cachedCandyViewControllers setObject:candyViewController forKey:candy];
    }
    return candyViewController;
}

- (void)removedCachedViewControllerForCandy:(WLCandy*)candy {
    WLCandyViewController *candyViewController = [self.cachedCandyViewControllers objectForKey:candy];
    if (candyViewController) {
        [self.cachedCandyViewControllers removeObjectForKey:candy];
    }
}

- (UIViewController *)viewControllerAfterViewController:(WLCandyViewController *)viewController {
    WLCandy *candy = viewController.candy;
    WLHistoryItem *item = self.historyItem;
    candy = [item.entries tryObjectAtIndex:[item.entries indexOfObject:candy] + 1];
    if (candy) {
        WLCandyViewController *candyViewController = [self candyViewController:candy];
        return candyViewController;
    }
    
    if (item.completed) {
        item = [self.history.entries tryObjectAtIndex:[self.history.entries indexOfObject:item] + 1];
        if (item) {
            WLCandyViewController *candyViewController = [self candyViewController:[item.entries firstObject]];
            return candyViewController;
        }
        [self fetchHistoryItemsOlderThen:self.historyItem];
    } else {
        [self fetchCandiesOlderThen:self.candy];
    }
    
    return nil;
}

- (UIViewController *)viewControllerBeforeViewController:(WLCandyViewController *)viewController {
    WLCandy *candy = viewController.candy;
    WLHistoryItem *item = self.historyItem;
    candy = [item.entries tryObjectAtIndex:[item.entries indexOfObject:candy] - 1];
    if (candy) {
        WLCandyViewController *candyViewController = [self candyViewController:candy];
        return candyViewController;
    } else {
        item = [self.history.entries tryObjectAtIndex:[self.history.entries indexOfObject:item] - 1];
        if (item) {
            WLCandyViewController *candyViewController = [self candyViewController:[item.entries lastObject]];
            return candyViewController;
        }
    }
    return nil;
}

- (void)didChangeViewController:(WLCandyViewController *)viewController {
    self.candy = [viewController candy];
    self.historyItem = [self.history itemWithCandy:self.candy];
    self.currentCandyIndex = [self.historyItem.entries indexOfObject:self.candy];
    self.currentHistoryItemIndex = [self.history.entries indexOfObject:self.historyItem];
    [self fetchCandiesOlderThen:self.candy];
    [self fetchHistoryItemsOlderThen:self.historyItem];
}

- (void)didChangeOffsetForViewController:(UIViewController *)viewController offset:(CGFloat)offset {
    viewController.view.alpha = offset;
}

#pragma mark - WLDeviceOrientationBroadcastReceiver

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
