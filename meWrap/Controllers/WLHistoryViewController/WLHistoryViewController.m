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
#import "WLDownloadingView.h"
#import "WLPresentingImageView.h"
#import "WLCommentsViewController.h"
#import "WLDrawingViewController.h"
#import "WLFollowingViewController.h"
#import "WLImageEditorSession.h"

static NSTimeInterval WLHistoryBottomViewModeTogglingInterval = 4;

typedef NS_ENUM(NSUInteger, WLHistoryBottomViewMode) {
    WLHistoryBottomViewModeCreating,
    WLHistoryBottomViewModeEditing
};

@interface WLHistoryViewController () <EntryNotifying>

@property (weak, nonatomic) IBOutlet EntryStatusIndicator *candyIndicator;
@property (weak, nonatomic) IBOutlet EntryStatusIndicator *commentIndicator;
@property (weak, nonatomic) IBOutlet LayoutPrioritizer *bottomViewHeightPrioritizer;
@property (weak, nonatomic) IBOutlet LayoutPrioritizer *primaryConstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIButton *drawButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *reportButton;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet WLButton *commentButton;
@property (weak, nonatomic) IBOutlet ImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet WLLabel *postLabel;
@property (weak, nonatomic) IBOutlet WLLabel *timeLabel;
@property (weak, nonatomic) IBOutlet WLTextView *lastCommentTextView;

@property (nonatomic) BOOL disableRotation;
@property (nonatomic) NSUInteger currentCandyIndex;
@property (nonatomic) WLHistoryBottomViewMode bottomViewMode;
@property (strong, nonatomic) NSMapTable *cachedCandyViewControllers;
@property (weak, nonatomic) Candy *removedCandy;
@property (weak, nonatomic) Comment *lastComment;
@property (weak, nonatomic) WLOperationQueue *paginationQueue;

@end

@implementation WLHistoryViewController

- (void)dealloc {
    [WLOperationQueue removeQueue:self.paginationQueue];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.contentView addGestureRecognizer:self.scrollView.panGestureRecognizer];
    
    __weak typeof(self)weakSelf = self;
    self.paginationQueue = [WLOperationQueue queueNamed:[NSString GUID] capacity:1];
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

    [[Candy notifier] addReceiver:self];
    
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
    Candy *candy = _candy;
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

- (void)setupBottomViewModeRelatedData:(WLHistoryBottomViewMode)bottomViewMode candy:(Candy *)candy {
    if (bottomViewMode == WLHistoryBottomViewModeEditing && candy.editor != nil) {
        _bottomViewMode = WLHistoryBottomViewModeEditing;
        self.postLabel.text = [NSString stringWithFormat:@"formatted_edited_by".ls, candy.editor.name];
        self.timeLabel.text = candy.editedAt.timeAgoStringAtAMPM;
    } else {
        _bottomViewMode = WLHistoryBottomViewModeCreating;
        self.postLabel.text = [NSString stringWithFormat:(candy.isVideo ? @"formatted_video_by" : @"formatted_photo_by").ls, candy.contributor.name];
        self.timeLabel.text = candy.createdAt.timeAgoStringAtAMPM;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.lastComment = nil;
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

- (void)setCandy:(Candy *)candy direction:(WLSwipeViewControllerDirection)direction animated:(BOOL)animated {
    _candy = candy;
    WLCandyViewController *candyViewController = [self candyViewController:candy];
    [self updateOwnerData];
    [self setViewController:candyViewController direction:direction animated:animated];
}

- (void)fetchCandiesOlderThen:(Candy *)candy {
    WLHistory *history = self.history;
    if (history.completed || !candy) return;
    [self.paginationQueue addOperationWithBlock:^(WLOperation *operation) {
        [history older:^(NSArray *candies) {
            [operation finish];
        } failure:^(NSError *error) {
            [operation finish];
        }];
    }];
}

- (void)setCandy:(Candy *)candy {
    if (candy != _candy) {
        _candy = candy.valid ? candy : nil;
        if (self.isViewLoaded) [self updateOwnerData];
    }
}

- (void)setLastComment:(Comment *)lastComment {
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
    Candy *candy = _candy;
    [candy markAsRead];
    [self.candyIndicator updateStatusIndicator:candy];
    [self setCommentButtonTitle:candy];
    [self setupBottomViewModeRelatedData:self.bottomViewMode candy:candy];
    self.lastComment = [candy latestComment];
    self.deleteButton.hidden = !candy.deletable;
    self.reportButton.hidden = !self.deleteButton.hidden;
    self.bottomViewHeightPrioritizer.defaultState = !self.avatarImageView.hidden;
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
    
    candy = [self.history.entries tryAt:self.currentCandyIndex];
    if (candy) {
        return candy;
    } else {
        candy = [self.history.entries tryAt:self.currentCandyIndex - 1];
        if (candy) {
            return candy;
        }
    }
    return [self.history.entries firstObject];
}

- (void)notifier:(EntryNotifier *)notifier didAddEntry:(Candy *)candy {
    self.currentCandyIndex = [self.history.entries indexOfObject:self.candy];
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
            [WLToast showWithMessage:(candy.isVideo ? @"video_deleted" : @"photo_deleted").ls];
            self.removedCandy = nil;
        } else {
            [WLToast showWithMessage:(candy.isVideo ? @"video_unavailable" : @"photo_unavailable").ls];
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
    [WLToast showMessageForUnavailableWrap:wrap];
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
            if (error.isNetworkError) {
                [WLToast showWithMessage:@"downloading_internet_connection_error".ls];
            } else {
                [error show];
            }
            sender.loading = NO;
        }];
    }];
}

- (IBAction)deleteCandy:(WLButton *)sender {
    __weak typeof(self)weakSelf = self;
    [WLFollowingViewController followWrapIfNeeded:self.wrap performAction:^{
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
    Candy *candy = self.candy;
    ReportViewController *controller = self.storyboard[@"report"];
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
    [WLFollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        __weak Candy *candy = weakSelf.candy;
        [weakSelf downloadCandyOriginal:candy success:^(UIImage *image) {
            [WLDrawingViewController draw:image finish:^(UIImage *image) {
                [candy editWithImage:image];
                sender.userInteractionEnabled = YES;
            }];
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
    [WLFollowingViewController followWrapIfNeeded:self.wrap performAction:^{
        for (UIViewController *controller in [self childViewControllers]) {
            if ([controller isKindOfClass:WLCommentsViewController.class]) {
                return;
            }
        }
        [weakSelf setBarsHidden:YES animated:YES];
        [self applyScaleToCandyViewController:YES];
        WLCommentsViewController *controller = weakSelf.storyboard[@"WLCommentsViewController"];
        controller.candy = weakSelf.candy;
        [controller presentForController:weakSelf animated:YES];
    }];
}

- (void)downloadCandyOriginal:(Candy *)candy success:(WLImageBlock)success failure:(WLFailureBlock)failure {
    if (candy) {
        NSError *error = [candy updateError];
        if (error) {
            if (failure) failure(error);
        } else {
            [WLDownloadingView downloadCandy:candy success:success failure:failure];
        }
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

- (WLCandyViewController *)candyViewController:(Candy *)candy {
    if (!self.cachedCandyViewControllers) {
        self.cachedCandyViewControllers = [NSMapTable weakToStrongObjectsMapTable];
    }
    WLCandyViewController *candyViewController = [self.cachedCandyViewControllers objectForKey:candy];
    if (!candyViewController) {
        candyViewController = self.storyboard[@"WLCandyViewController"];
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
    candy = [self.history.entries tryAt:[self.history.entries indexOfObject:candy] + 1];
    if (candy) {
        return [self candyViewController:candy];
    }
    
    if (!self.history.completed) {
        [self fetchCandiesOlderThen:candy];
    }
    
    return nil;
}

- (UIViewController *)viewControllerBeforeViewController:(WLCandyViewController *)viewController {
    Candy *candy = viewController.candy;
    candy = [self.history.entries tryAt:[self.history.entries indexOfObject:candy] - 1];
    if (candy) {
        return [self candyViewController:candy];
    } else {
        return nil;
    }
}

- (void)didChangeViewController:(WLCandyViewController *)viewController {
    self.candy = [viewController candy];
    self.currentCandyIndex = [self.history.entries indexOfObject:self.candy];
    [self fetchCandiesOlderThen:self.candy];
}

- (void)didChangeOffsetForViewController:(UIViewController *)viewController offset:(CGFloat)offset {
    viewController.view.alpha = offset;
}

// MARK: - WLDeviceManagerReceiver

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
