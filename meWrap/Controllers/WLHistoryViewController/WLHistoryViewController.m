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
#import "WLToast.h"
#import "WLCandyViewController.h"
#import "WLNavigationHelper.h"
#import "WLDownloadingView.h"
#import "WLImageCache.h"
#import "WLPresentingImageView.h"
#import "WLCommentsViewController.h"
#import "WLAlertView.h"
#import "WLDrawingViewController.h"
#import "WLFollowingViewController.h"
#import "PHPhotoLibrary+Helper.h"
#import "WLEntry+WLUploadingQueue.h"
#import "WLImageEditorSession.h"

static NSTimeInterval WLHistoryBottomViewModeTogglingInterval = 4;

typedef NS_ENUM(NSUInteger, WLHistoryBottomViewMode) {
    WLHistoryBottomViewModeCreating,
    WLHistoryBottomViewModeEditing
};

@interface WLHistoryViewController () <WLEntryNotifyReceiver, VideoPlayerViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet WLButton *commentButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *reportButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIButton *drawButton;
@property (weak, nonatomic) IBOutlet WLLabel *postLabel;
@property (weak, nonatomic) IBOutlet WLLabel *timeLabel;
@property (weak, nonatomic) IBOutlet EntryStatusIndicator *commentIndicator;
@property (weak, nonatomic) IBOutlet EntryStatusIndicator *candyIndicator;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *playLabel;

@property (weak, nonatomic) WLComment *lastComment;

@property (weak, nonatomic) IBOutlet WLImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet WLTextView *lastCommentTextView;
@property (weak, nonatomic) IBOutlet VideoPlayerView *videoPlayerView;

@property (weak, nonatomic) IBOutlet LayoutPrioritizer *primaryConstraint;
@property (weak, nonatomic) IBOutlet LayoutPrioritizer *commentButtonPrioritizer;
@property (weak, nonatomic) IBOutlet LayoutPrioritizer *bottomViewHeightPrioritizer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) NSMapTable *cachedCandyViewControllers;

@property (nonatomic) NSUInteger currentCandyIndex;

@property (nonatomic) NSUInteger currentHistoryItemIndex;

@property (weak, nonatomic) WLCandy* removedCandy;

@property (nonatomic) WLHistoryBottomViewMode bottomViewMode;

@property (nonatomic) BOOL disableRotation;

@property (weak, nonatomic) WLOperationQueue *paginationQueue;



@end

@implementation WLHistoryViewController

- (void)dealloc {
    [WLOperationQueue removeQueue:self.paginationQueue];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.contentView addGestureRecognizer:self.scrollView.panGestureRecognizer];
    self.videoPlayerView.delegate = self;
    
    __weak typeof(self)weakSelf = self;
    self.paginationQueue = [WLOperationQueue queueNamed:GUID() capacity:1];
    [self.paginationQueue setStartQueueBlock:^{
        [weakSelf.spinner startAnimating];
    }];
    [self.paginationQueue setFinishQueueBlock:^{
        [weakSelf.spinner stopAnimating];
    }];
    
    self.lastCommentTextView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    self.lastCommentTextView.textContainer.maximumNumberOfLines = 2;
    self.lastCommentTextView.textContainerInset = UIEdgeInsetsZero;
    self.lastCommentTextView.textContainer.lineFragmentPadding = .0;
    
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

    [[WLCandy notifier] addReceiver:self];
    
    self.commentButton.layer.borderColor = [UIColor whiteColor].CGColor;

    [self setCandy:_candy direction:0 animated:NO];
    
    [UIView performWithoutAnimation:^{
        [UIViewController attemptRotationToDeviceOrientation];
    }];
    
    if (self.showCommentViewController) {
        [self showCommentView];
    }
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
        _bottomViewMode = WLHistoryBottomViewModeEditing;
        self.postLabel.text = [NSString stringWithFormat:WLLS(@"formatted_edited_by"), candy.editor.name];
        self.timeLabel.text = candy.editedAt.timeAgoStringAtAMPM;
    } else {
        _bottomViewMode = WLHistoryBottomViewModeCreating;
        self.postLabel.text = [NSString stringWithFormat:[candy messageAppearanceByCandyType:@"formatted_video_by"
                                                                                         and:@"formatted_photo_by"], candy.contributor.name];
        self.timeLabel.text = candy.createdAt.timeAgoStringAtAMPM;
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
    if (_candy.isVideo) {
        self.videoPlayerView.playButton.hidden = YES;
        self.videoPlayerView.timeView.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
   
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

- (void)setBarsHidden:(BOOL)hidden animated:(BOOL)animated {
    [self.primaryConstraint setDefaultState:!hidden animated:animated];
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
    [self.paginationQueue addOperationWithBlock:^(WLOperation *operation) {
        [historyItem older:^(NSSet *candies) {
            [operation finish];
        } failure:^(NSError *error) {
            if (error.isNetworkError) {
                historyItem.completed = YES;
            }
            [operation finish];
        }];
    }];
}

- (void)fetchHistoryItemsOlderThen:(WLHistoryItem*)historyItem {
    WLHistory *history = self.history;
    if (history.completed || history.request.loading || !historyItem) return;
    [self.paginationQueue addOperationWithBlock:^(WLOperation *operation) {
        [history older:^(NSSet *candies) {
            [operation finish];
        } failure:^(NSError *error) {
            if (error.isNetworkError) {
                historyItem.completed = YES;
            }
            [operation finish];
        }];
    }];
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
            UIBezierPath *exlusionPath = [UIBezierPath bezierPathWithRect:[self.bottomView convertRect:self.commentIndicator.frame
                                                                                                toView:textView]];
            textView.textContainer.exclusionPaths = [self.lastComment.contributor current] ? @[exlusionPath] : nil;
        }
    }
}

- (void)updateOwnerData {
    WLCandy *candy = _candy;
    [candy markAsRead];
    [self.candyIndicator updateStatusIndicator:candy];
    [self setCommentButtonTitle:candy];
    [self setupBottomViewModeRelatedData:self.bottomViewMode candy:candy];
    self.lastComment = [candy latestComment];
    self.deleteButton.hidden = !candy.deletable;
    self.reportButton.hidden = !self.deleteButton.hidden;
    NSInteger type = candy.type;
    if (type == WLCandyTypeVideo) {
        NSString *url = candy.picture.original;
        if ([[NSFileManager defaultManager] fileExistsAtPath:url]) {
            self.videoPlayerView.url = [NSURL fileURLWithPath:url];
        } else {
            self.videoPlayerView.url = [NSURL URLWithString:url];
        }
        self.drawButton.hidden = self.editButton.hidden = YES;
        self.videoPlayerView.hidden = NO;
    } else {
        self.videoPlayerView.url = nil;
        self.videoPlayerView.hidden = YES;
        self.drawButton.hidden = self.editButton.hidden = NO;
    }
    self.bottomViewHeightPrioritizer.defaultState = !self.avatarImageView.hidden;
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

// MARK: - WLEntryNotifyReceiver

- (WLCandy*)candyAfterDeletingCandy:(WLCandy*)candy {
    
    if (!self.wrap.candies.nonempty) {
        return nil;
    }
    
    candy = [self.historyItem.entries tryAt:self.currentCandyIndex];
    if (candy) {
        return candy;
    }
    
    WLHistoryItem *nextItem = nil;
    if ([self.history.entries containsObject:self.historyItem]) {
        nextItem = [self.history.entries tryAt:[self.history.entries indexOfObject:self.historyItem] + 1];
    } else {
        nextItem = [self.history.entries tryAt:self.currentHistoryItemIndex];
    }
    if (nextItem) {
        self.historyItem = nextItem;
        return [nextItem.entries firstObject];
    }
    
    candy = [self.historyItem.entries tryAt:self.currentCandyIndex - 1];
    if (candy) {
        return candy;
    }
    
    WLHistoryItem *previousItem = nil;
    if ([self.history.entries containsObject:self.historyItem]) {
        previousItem = [self.history.entries tryAt:[self.history.entries indexOfObject:self.historyItem] - 1];
    } else {
        previousItem = [self.history.entries tryAt:self.currentHistoryItemIndex - 1];
    }
    if (previousItem) {
        self.historyItem = previousItem;
        return [previousItem.entries lastObject];
    }
    
    return [self.historyItem.entries firstObject];
}

- (void)notifier:(WLEntryNotifier *)notifier didAddEntry:(WLCandy *)candy {
    self.currentCandyIndex = [self.historyItem.entries indexOfObject:self.candy];
    self.currentHistoryItemIndex = [self.history.entries indexOfObject:self.historyItem];
}

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLCandy *)candy {
    if (candy == self.candy) {
        [self updateOwnerData];
    }
}

- (void)notifier:(WLEntryNotifier *)notifier willDeleteEntry:(WLCandy *)candy {
    if (candy == self.candy) {
        if (self.navigationController.presentedViewController) {
            [self.navigationController dismissViewControllerAnimated:NO completion:nil];
        }
        if (self.removedCandy == candy) {
            [WLToast showWithMessage:[candy messageAppearanceByCandyType:@"video_deleted" and:@"photo_deleted"]];
            self.removedCandy = nil;
        } else {
            [WLToast showWithMessage:[candy messageAppearanceByCandyType:@"video_unavailable" and:@"photo_unavailable"]];
        }
        WLCandy *nextCandy = [self candyAfterDeletingCandy:candy];
        if (nextCandy) {
            [self setCandy:nextCandy direction:0 animated:NO];
            [self setBarsHidden:NO animated:YES];
        } else {
            [self.navigationController popViewControllerAnimated:NO];
        }
    }
    [self removedCachedViewControllerForCandy:candy];
}

- (void)notifier:(WLEntryNotifier *)notifier willDeleteContainer:(WLWrap *)wrap {
    [WLToast showMessageForUnavailableWrap:wrap];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return entry.container == self.wrap;
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnContainer:(WLEntry *)entry {
    return self.wrap == entry;
}

// MARK: - Actions

- (IBAction)back:(id)sender {
    BOOL animate = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    WLCandy* candy = self.candy;
    if (candy.valid) {
        if (self.presentingImageView != nil && animate) {
            [self.navigationController popViewControllerAnimated:NO];
            [self.presentingImageView dismissCandy:candy];
        } else {
            [self.navigationController popViewControllerAnimated:animate];
        }
    } else {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
    
}

- (IBAction)downloadCandy:(WLButton*)sender {
    __weak typeof(self)weakSelf = self;
    [WLFollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        sender.loading = YES;
        [weakSelf.candy download:^{
            sender.loading = NO;
            [WLToast showDownloadingMediaMessageForCandy:weakSelf.candy];
        } failure:^(NSError *error) {
            sender.loading = NO;
            [error show];
        }];
    }];
}

- (IBAction)deleteCandy:(WLButton *)sender {
    __weak typeof(self)weakSelf = self;
    [WLFollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        WLCandy *candy = weakSelf.candy;
        [UIAlertController confirmCandyDeleting:candy success:^{
            weakSelf.removedCandy = candy;
            sender.loading = YES;
            [candy remove:^(id object) {
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
    WLCandy *candy = self.candy;
    ReportViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"report"];
    [controller setReportClosure:^(NSString * code, ReportViewController *controller) {
        [[WLAPIRequest postCandy:candy violationCode:code] send:^(id object) {
            [controller reportingFinished];
        } failure:^(NSError *error) {
            [error show];
        }];
    }];
    [self.navigationController pushViewController:controller animated:NO];
}

- (IBAction)editPhoto:(id)sender {
    __weak typeof(self)weakSelf = self;
    [WLFollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        __weak WLCandy *candy = weakSelf.candy;
        [weakSelf downloadCandyOriginal:candy success:^(UIImage *image) {
            [WLImageEditorSession editImage:image completion:^(UIImage *image) {
                [candy editWithImage:image];
            } cancel:nil];
        } failure:^(NSError *error) {
            [error show];
        }];
    }];
}

- (IBAction)draw:(id)sender {
    __weak __typeof(self)weakSelf = self;
    [WLFollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        __weak WLCandy *candy = weakSelf.candy;
        [weakSelf downloadCandyOriginal:candy success:^(UIImage *image) {
            [WLDrawingViewController draw:image finish:^(UIImage *image) {
                [candy editWithImage:image];
            }];
        } failure:^(NSError *error) {
            [error show];
        }];
    }];
}

- (IBAction)comments:(id)sender {
    __weak typeof(self)weakSelf = self;
    [WLFollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        for (UIViewController *controller in [self childViewControllers]) {
            if ([controller isKindOfClass:WLCommentsViewController.class]) {
                return;
            }
        }
        [weakSelf setBarsHidden:YES animated:YES];
        [self applyScaleToCandyViewController:YES];
        WLCommentsViewController *controller = [WLCommentsViewController instantiate:weakSelf.storyboard];
        controller.candy = weakSelf.candy;
        [controller presentForController:weakSelf animated:YES];
    }];
}

- (void)downloadCandyOriginal:(WLCandy*)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure {
    if (candy) {
        [candy prepareForUpdate:^(WLContribution *contribution, WLContributionStatus status) {
            [WLDownloadingView downloadCandy:candy success:success failure:failure];
        } failure:failure];
    } else {
        if (failure) failure(nil);
    }
}

- (IBAction)toggleBottomViewMode:(id)sender {
    if ([self.postLabel.superview.layer animationKeys].count == 0) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(toggleBottomViewMode) object:nil];
        [self toggleBottomViewMode];
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
    
    if (candy.isVideo) {
        self.videoPlayerView.playButton.hidden = YES;
        self.videoPlayerView.timeView.hidden = YES;
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
    candy = [item.entries tryAt:[item.entries indexOfObject:candy] + 1];
    if (candy) {
        return [self candyViewController:candy];
    }
    
    if (item.completed) {
        item = [self.history.entries tryAt:[self.history.entries indexOfObject:item] + 1];
        if (item) {
            return [self candyViewController:[item.entries firstObject]];
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
    candy = [item.entries tryAt:[item.entries indexOfObject:candy] - 1];
    if (candy) {
        return [self candyViewController:candy];
    } else {
        item = [self.history.entries tryAt:[self.history.entries indexOfObject:item] - 1];
        if (item) {
            return [self candyViewController:[item.entries lastObject]];
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

// MARK: - WLDeviceOrientationBroadcastReceiver

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.disableRotation ? [super supportedInterfaceOrientations] : UIInterfaceOrientationMaskAll;
}

// MARK: - VideoPlayerViewDelegate

- (void)hideAllViews {
    [self hideVideoPlayingViews:YES];
    [self hideSecondaryViews:YES];
}

- (void)hideVideoPlayingViews:(BOOL)hide {
    self.videoPlayerView.playButton.hidden = hide;
    self.videoPlayerView.timeView.hidden = hide;
    [self.videoPlayerView.playButton fade];
    [self.videoPlayerView.timeView fade];
}

- (void)hideSecondaryViews:(BOOL)hide {
    self.bottomView.hidden = hide;
    self.topView.hidden = hide;
    self.commentButton.hidden = hide;
    [self.bottomView fade];
    [self.topView fade];
    [self.commentButton fade];
}

- (void)videoPlayerViewDidPlay:(VideoPlayerView *)view {
    [self setBarsHidden:NO animated:YES];
    self.playLabel.hidden = YES;
    self.scrollView.panGestureRecognizer.enabled = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAllViews) object:nil];
    [self hideVideoPlayingViews:NO];
    [self hideSecondaryViews:NO];
    [self performSelector:@selector(hideAllViews) withObject:nil afterDelay:4];
}

- (void)videoPlayerViewDidPause:(VideoPlayerView *)view {
    [self hideVideoPlayingViews:NO];
    [self hideSecondaryViews:NO];
    self.scrollView.panGestureRecognizer.enabled = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAllViews) object:nil];
}

- (void)videoPlayerViewSeekedToTime:(VideoPlayerView *)view {
    if (view.playing) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAllViews) object:nil];
        [self performSelector:@selector(hideAllViews) withObject:nil afterDelay:4];
    }
}

- (void)videoPlayerViewDidPlayToEnd:(VideoPlayerView *)view {
    self.playLabel.hidden = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAllViews) object:nil];
    [self hideSecondaryViews:NO];
    [self hideVideoPlayingViews:YES];
}

// MARK: - CommentViewControllerDelegate

- (void)applyScaleToCandyViewController:(BOOL)apply {
     WLCandyViewController *candyViewController = [self candyViewController:self.candy];
    [UIView animateWithDuration:.25 animations:^{
        candyViewController.view.transform = apply ? CGAffineTransformMakeScale(0.9, 0.9) : CGAffineTransformIdentity;
    }];
    [self setBarsHidden:apply animated:YES];
}

@end
