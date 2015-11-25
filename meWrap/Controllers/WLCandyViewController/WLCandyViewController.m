//
//  WLWrapDataViewController.m
//  meWrap
//
//  Created by Ravenpod on 3/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandyViewController.h"
#import "WLDeviceManager.h"
#import "WLToast.h"
#import "WLImageView.h"
@import AVKit;
@import AVFoundation;

@interface WLCandyViewController () <EntryNotifying, UIScrollViewDelegate, VideoPlayerViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aspectRatioConstraint;
@property (weak, nonatomic) IBOutlet VideoPlayerView *videoPlayerView;
@property (strong, nonatomic) CandyInteractionController *candyInteractionController;

@end

@implementation WLCandyViewController

- (void)dealloc {
    self.scrollView.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.scrollView.userInteractionEnabled = NO;
    [[WLDeviceManager defaultManager] addReceiver:self];
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 2;
    
    [self.scrollView.superview addGestureRecognizer:self.scrollView.panGestureRecognizer];
    [self.scrollView.superview addGestureRecognizer:self.scrollView.pinchGestureRecognizer];
    self.scrollView.panGestureRecognizer.enabled = NO;
    
    [[Candy notifier] addReceiver:self];
    
    self.videoPlayerView.delegate = self;
    
    [self setup:self.candy];
    [self refresh];
    __weak __typeof(self)weakSelf = self;
     self.candyInteractionController = [[CandyInteractionController alloc] initWithViewController:self
                                                                               interactionHandler:^(BOOL hidden) {
        weakSelf.videoPlayerView.timeView.hidden = weakSelf.videoPlayerView.secondaryPlayButton.hidden = hidden;
        [weakSelf.videoPlayerView.timeView addAnimation:[CATransition transition:kCATransitionFade]];
        [weakSelf.videoPlayerView.secondaryPlayButton addAnimation:[CATransition transition:kCATransitionFade]];
        [weakSelf.historyViewController hideSecondaryViews:hidden];
     }];
}

- (void)setup:(Candy *)candy {
    __weak typeof(self)weakSelf = self;
    self.spinner.hidden = NO;
    self.errorLabel.hidden = YES;
    [self.imageView setUrl:candy.picture.large success:^(UIImage *image, BOOL cached) {
        [weakSelf calculateScaleValues];
        weakSelf.scrollView.userInteractionEnabled = YES;
        weakSelf.spinner.hidden = weakSelf.errorLabel.hidden = YES;
    } failure:^(NSError *error) {
        weakSelf.errorLabel.hidden = ![error isNetworkError];
        weakSelf.spinner.hidden = YES;
    }];
    VideoPlayerView *playerView = self.videoPlayerView;
    NSInteger type = candy.type;
    if (type == MediaTypeVideo) {
        if (!playerView.playing) {
            playerView.url = [candy.picture.original smartURL];
        }
        playerView.hidden = NO;
    } else {
        playerView.url = nil;
        playerView.hidden = YES;
    }
}

- (void)calculateScaleValues {
    UIImage *image = self.imageView.image;
    if (image) {
        NSLayoutConstraint *constraint = self.aspectRatioConstraint;
        constraint = [NSLayoutConstraint constraintWithItem:constraint.firstItem attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:constraint.secondItem attribute:constraint.secondAttribute multiplier:image.size.width/image.size.height constant:0];
        [self.scrollView removeConstraint:self.aspectRatioConstraint];
        [self.scrollView addConstraint:constraint];
        self.aspectRatioConstraint = constraint;
        [self.scrollView layoutIfNeeded];
        self.scrollView.zoomScale = 1;
        self.scrollView.panGestureRecognizer.enabled = NO;
    }
}

- (void)refresh {
    [self refresh:self.candy];
}

- (void)refresh:(Candy *)candy {
    [candy fetch:^(id object) { } failure:^(NSError *error) { }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    BOOL shouldBeShow = _candy.isVideo && ![self.videoPlayerView.spinner isAnimating];
    self.videoPlayerView.placeholderPlayButton.hidden = self.videoPlayerView.playButton.hidden = !shouldBeShow;
    self.videoPlayerView.secondaryPlayButton.hidden = self.videoPlayerView.timeView.hidden = YES;
    self.videoPlayerView.timeViewPrioritizer.defaultState = _candy.latestComment.text.nonempty;
}

- (void)setCandy:(Candy *)candy {
    if (candy != _candy && candy.valid) {
        _candy = candy;
        if (self.isViewLoaded) {
            [self setup:self.candy];
            [self refresh];
        }
    }
}

#pragma mark - EntryNotifying

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(Candy * _Nonnull)entry event:(enum EntryUpdateEvent)event {
    self.videoPlayerView.timeViewPrioritizer.defaultState = entry.latestComment.text.nonempty;
    if (event == EntryUpdateEventDefault) {
        [self setup:entry];
    }
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return self.candy == entry;
}

#pragma mark - WLDeviceManagerReceiver

- (void)manager:(WLDeviceManager *)manager didChangeOrientation:(NSNumber*)orientation {
    self.scrollView.zoomScale = 1;
    self.scrollView.panGestureRecognizer.enabled = NO;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    scrollView.panGestureRecognizer.enabled = scale > scrollView.minimumZoomScale;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

// MARK: - VideoPlayerViewDelegate

- (void)hideAllViews {
    [self.videoPlayerView hiddenCenterViews:YES];
    [self.videoPlayerView hiddenBottomViews:YES];
    [self.historyViewController hideSecondaryViews:YES];
}

- (void)videoPlayerViewDidPlay:(VideoPlayerView *)view {
    self.candyInteractionController.allowGesture = NO;
    self.historyViewController.scrollView.panGestureRecognizer.enabled = NO;
    [self.historyViewController setBarsHidden:NO animated:YES];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAllViews) object:nil];
    [self performSelector:@selector(hideAllViews) withObject:nil afterDelay:4];
}

- (void)videoPlayerViewDidPause:(VideoPlayerView *)view {
    self.historyViewController.commentPressed = ^ {
        [view pause];
    };
    [self.historyViewController  hideSecondaryViews:NO];
    self.candyInteractionController.allowGesture = YES;
    self.historyViewController.scrollView.panGestureRecognizer.enabled = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAllViews) object:nil];
}

- (void)videoPlayerViewSeekedToTime:(VideoPlayerView *)view {
    if (view.playing) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAllViews) object:nil];
        [self performSelector:@selector(hideAllViews) withObject:nil afterDelay:4];
    }
}

- (void)videoPlayerViewDidPlayToEnd:(VideoPlayerView *)view {
    [self.historyViewController hideSecondaryViews:NO];
    self.candyInteractionController.allowGesture = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAllViews) object:nil];
}

@end
