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

@interface WLCandyViewController () <EntryNotifying, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aspectRatioConstraint;

@end

@implementation WLCandyViewController

- (void)dealloc {
    self.scrollView.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.scrollView.userInteractionEnabled = NO;
    [[WLDeviceManager manager] addReceiver:self];
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 2;
    
    [self.scrollView.superview addGestureRecognizer:self.scrollView.panGestureRecognizer];
    [self.scrollView.superview addGestureRecognizer:self.scrollView.pinchGestureRecognizer];
    self.scrollView.panGestureRecognizer.enabled = NO;
    
    [[Candy notifier] addReceiver:self];
    
    [self setup:self.candy];
    [self refresh];
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

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(Candy *)candy {
    [self setup:candy];
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return self.candy == entry;
}

#pragma mark - WLDeviceOrientationBroadcastReceiver

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

@end
