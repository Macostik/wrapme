//
//  WLWrapDataViewController.m
//  meWrap
//
//  Created by Ravenpod on 3/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandyViewController.h"
@import AVKit;
@import AVFoundation;

@interface WLCandyViewController () <EntryNotifying, UIScrollViewDelegate, VideoPlayerViewDelegate, SlideInteractiveTransitionDelegate, NetworkNotifying>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aspectRatioConstraint;
@property (weak, nonatomic) IBOutlet VideoPlayerView *videoPlayerView;
@property (strong, nonatomic) SlideInteractiveTransition *slideInteractiveTransition;

@end

@implementation WLCandyViewController

- (void)dealloc {
    self.scrollView.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollView.userInteractionEnabled = NO;
    [[DeviceManager defaultManager] addReceiver:self];
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 2;
    
    [self.scrollView.superview addGestureRecognizer:self.scrollView.panGestureRecognizer];
    [self.scrollView.superview addGestureRecognizer:self.scrollView.pinchGestureRecognizer];
    self.scrollView.panGestureRecognizer.enabled = NO;
    
    [[Candy notifier] addReceiver:self];
    
    self.videoPlayerView.delegate = self;
    
    [self.candy fetch:nil failure:nil];
    self.slideInteractiveTransition = [[SlideInteractiveTransition alloc] initWithContentView:self.contentView imageView:self.imageView];
    self.slideInteractiveTransition.delegate = self;
}

- (void)setup:(Candy *)candy {
    __weak typeof(self)weakSelf = self;
    self.spinner.hidden = NO;
    self.errorLabel.hidden = YES;
    
    VideoPlayerView *playerView = self.videoPlayerView;
    NSInteger type = candy.type;
    if (type == MediaTypeVideo) {
        if (!playerView.playing) {
            NSString *original = candy.asset.original;
            if (original) {
                if ([original isExistingFilePath]) {
                    playerView.url = [original fileURL];
                } else {
                    NSString *path = [[[ImageCache defaultCache] getPath:[ImageCache uidFromURL:original]] stringByAppendingPathExtension:@"mp4"];
                    if ([path isExistingFilePath]) {
                        playerView.url = [path fileURL];
                    } else {
                        playerView.url = [original URL];
                    }
                }
            }
        }
        playerView.hidden = NO;
    } else {
        playerView.url = nil;
        playerView.hidden = YES;
    }
    
    [self.imageView setURL:candy.asset.large success:^(UIImage *image, BOOL cached) {
        [weakSelf calculateScaleValues];
        weakSelf.scrollView.userInteractionEnabled = YES;
        weakSelf.spinner.hidden = weakSelf.errorLabel.hidden = YES;
    } failure:^(NSError *error) {
        if ([error isNetworkError]) {
            [[Network sharedNetwork] addReceiver:self];
            weakSelf.errorLabel.hidden = NO;
            playerView.hidden = YES;
        } else {
            weakSelf.errorLabel.hidden = YES;
        }
        weakSelf.spinner.hidden = YES;
    }];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    [self setup:self.candy];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    BOOL shouldBeShow = _candy.isVideo && ![self.videoPlayerView.spinner isAnimating];
    self.videoPlayerView.placeholderPlayButton.hidden = self.videoPlayerView.playButton.hidden = !shouldBeShow;
    self.videoPlayerView.secondaryPlayButton.hidden = self.videoPlayerView.timeView.hidden = YES;
    self.videoPlayerView.timeViewPrioritizer.defaultState = _candy.latestComment.text.nonempty;
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

#pragma mark - DeviceManagerNotifying

- (void)manager:(DeviceManager *)manager didChangeOrientation:(UIDeviceOrientation)orientation {
    self.scrollView.zoomScale = 1;
    self.scrollView.panGestureRecognizer.enabled = NO;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    scrollView.panGestureRecognizer.enabled = scale > scrollView.minimumZoomScale;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.candy.type == MediaTypeVideo ? nil : self.imageView;
}

// MARK: - VideoPlayerViewDelegate

- (void)hideAllViews {
    [self.videoPlayerView hiddenCenterViews:YES];
    [self.videoPlayerView hiddenBottomViews:YES];
    [self.historyViewController hideSecondaryViews:YES];
}

- (void)videoPlayerViewDidPlay:(VideoPlayerView *)view {
    self.slideInteractiveTransition.panGestureRecognizer.enabled = NO;
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
    self.slideInteractiveTransition.panGestureRecognizer.enabled = YES;
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
    self.slideInteractiveTransition.panGestureRecognizer.enabled = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAllViews) object:nil];
}

// MARK: - SlideInteractiveTransitionDelegate

- (void)slideInteractiveTransition:(SlideInteractiveTransition *)controller hideViews:(BOOL)hideViews {
    VideoPlayerView *videoPlayerView = self.videoPlayerView;
    videoPlayerView.timeView.hidden = videoPlayerView.secondaryPlayButton.hidden = hideViews || !videoPlayerView.playButton.hidden;
    [videoPlayerView.timeView addAnimation:[CATransition transition:kCATransitionFade subtype:nil duration:0.33]];
    [videoPlayerView.secondaryPlayButton addAnimation:[CATransition transition:kCATransitionFade subtype:nil duration:0.33]];
    [self.historyViewController hideSecondaryViews:hideViews];
}

- (UIView *)slideInteractiveTransitionSnapshotView:(SlideInteractiveTransition *)controller {
    NSArray *viewControllers = self.historyViewController.navigationController.viewControllers;
    return [[viewControllers tryAt:[viewControllers indexOfObject:self.historyViewController] - 1] view];
}

- (void)slideInteractiveTransitionDidFinish:(SlideInteractiveTransition *)controller {
    [self.historyViewController.navigationController popViewControllerAnimated:NO];
}

- (UIView *)slideInteractiveTransitionPresentingView:(SlideInteractiveTransition *)controller {
    if (self.historyViewController.dismissingView == nil) return nil;
    UIView *dismissingView = self.historyViewController.dismissingView(nil, self.candy);
    dismissingView.alpha = 0;
    return dismissingView;
}

// MARK: - NetworkNotifying

- (void)networkDidChangeReachability:(Network *)network {
    if ([network reachable]) {
        [self setup:self.candy];
        [network removeReceiver:self];
    }
}

@end
