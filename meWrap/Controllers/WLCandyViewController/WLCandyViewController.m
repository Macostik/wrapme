//
//  WLWrapDataViewController.m
//  meWrap
//
//  Created by Ravenpod on 3/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandyViewController.h"
#import "WLDeviceOrientationBroadcaster.h"
#import "WLToast.h"
@import AVKit;
@import AVFoundation;

@interface WLCandyViewController () <WLEntryNotifyReceiver, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aspectRatioConstraint;
@property (weak, nonatomic) IBOutlet UIButton *playVideoButton;
@property (weak, nonatomic) VideoPlayerView *videoPlayerView;

@end

@implementation WLCandyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.scrollView.userInteractionEnabled = NO;
    [[WLDeviceOrientationBroadcaster broadcaster] addReceiver:self];
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 2;
    
    [self.scrollView.superview addGestureRecognizer:self.scrollView.panGestureRecognizer];
    [self.scrollView.superview addGestureRecognizer:self.scrollView.pinchGestureRecognizer];
    self.scrollView.panGestureRecognizer.enabled = NO;
    
    [[WLCandy notifier] addReceiver:self];
    
    [self setup:self.candy];
    [self refresh];
}

- (void)setup:(WLCandy *)candy {
    __weak typeof(self)weakSelf = self;
    self.spinner.hidden = NO;
    self.errorLabel.hidden = YES;
    self.playVideoButton.hidden = candy.type != WLCandyTypeVideo;
    [self.imageView setUrl:candy.picture.large success:^(UIImage *image, BOOL cached) {
        [weakSelf calculateScaleValues];
        weakSelf.scrollView.userInteractionEnabled = YES;
        weakSelf.spinner.hidden = weakSelf.errorLabel.hidden = YES;
    } failure:^(NSError *error) {
        weakSelf.errorLabel.hidden = ![error isNetworkError];
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

- (void)refresh {
    [self refresh:self.candy];
}

- (void)refresh:(WLCandy*)candy {
    [candy fetch:^(id object) { } failure:^(NSError *error) { }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)setCandy:(WLCandy *)candy {
    if (candy != _candy && candy.valid) {
        _candy = candy;
        if (self.isViewLoaded) {
            [self setup:self.candy];
            [self refresh];
        }
    }
}

- (IBAction)playVideo:(id)sender {
    VideoPlayerView *view = [[VideoPlayerView alloc] initWithFrame:self.view.bounds];
    
    NSString *url = self.candy.picture.original;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:url]) {
        view.url = [NSURL fileURLWithPath:url];
    } else {
        view.url = [NSURL URLWithString:url];
    }
    
    [self.view addSubview:view];
    
    [view play];
    
    self.videoPlayerView = view;
//    AVPlayerViewController *controller = [[AVPlayerViewController alloc] init];
//    
//    if ([[NSFileManager defaultManager] fileExistsAtPath:url]) {
//        controller.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:url]];
//    } else {
//        controller.player = [AVPlayer playerWithURL:[NSURL URLWithString:url]];
//    }
//    
//    [self presentViewController:controller animated:NO completion:nil];
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLCandy *)candy {
    [self setup:candy];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return self.candy == entry;
}

#pragma mark - WLDeviceOrientationBroadcastReceiver

- (void)broadcaster:(WLDeviceOrientationBroadcaster *)broadcaster didChangeOrientation:(NSNumber*)orientation {
    self.scrollView.zoomScale = 1;
    self.scrollView.panGestureRecognizer.enabled = NO;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    scrollView.panGestureRecognizer.enabled = scale > scrollView.minimumZoomScale;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

@end
