//
//  WLImageViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 23.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLImageViewController.h"
#import "WLImageFetcher.h"
#import "WLCandy.h"
#import "UIView+Shorthand.h"
#import "WLDeviceOrientationBroadcaster.h"
#import "NSError+WLAPIManager.h"
#import "UIView+AnimationHelper.h"

@interface WLScrollView : UIScrollView <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIView* zoomingView;

@end

@implementation WLScrollView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.delegate = self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.zoomingView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.zoomingView.frame = frameToCenter;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.zoomingView;
}

@end

@interface WLImageViewController () <UIScrollViewDelegate, WLDeviceOrientationBroadcastReceiver>

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

@end

@implementation WLImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.scrollView.userInteractionEnabled = NO;
	__weak typeof(self)weakSelf = self;
	[self.imageView setUrl:self.image.picture.large success:^(UIImage *image, BOOL cached) {
        if (image) {
            [weakSelf applyDeviceOrientation:[UIDevice currentDevice].orientation animated:NO];
			[weakSelf calculateScaleValues];
		}
		[weakSelf.spinner removeFromSuperview];
		weakSelf.scrollView.userInteractionEnabled = YES;
        weakSelf.errorLabel.hidden = YES;
    } failure:^(NSError *error) {
        [weakSelf.spinner removeFromSuperview];
        if ([error isNetworkError]) {
            weakSelf.errorLabel.hidden = NO;
        } else {
            weakSelf.errorLabel.hidden = YES;
            weakSelf.imageView.contentMode = UIViewContentModeCenter;
            weakSelf.imageView.image = [UIImage imageNamed:@"ic_photo_placeholder"];
        }
    }];
	
    [[WLDeviceOrientationBroadcaster broadcaster] addReceiver:self];
	[self applyDeviceOrientation:[UIDevice currentDevice].orientation animated:NO];
}

- (void)calculateScaleValues {
    CGFloat minimumZoomScale = CGSizeScaleToFitSize(self.view.size, self.imageView.image.size);
    if (minimumZoomScale <= 0) minimumZoomScale = 0.01;
    self.scrollView.maximumZoomScale = minimumZoomScale < 1 ? 2 : (minimumZoomScale + 2);
    self.scrollView.minimumZoomScale = minimumZoomScale;
    self.scrollView.zoomScale  = minimumZoomScale;
}

- (void)applyDeviceOrientation:(UIDeviceOrientation)orientation animated:(BOOL)animated {
	CGAffineTransform transform = self.view.transform;
	if (orientation == UIDeviceOrientationLandscapeLeft) {
		transform = CGAffineTransformMakeRotation(M_PI_2);
	} else if (orientation == UIDeviceOrientationLandscapeRight) {
		transform = CGAffineTransformMakeRotation(3*M_PI_2);
	} else if (orientation == UIDeviceOrientationPortrait) {
		transform = CGAffineTransformIdentity;
	} else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
		transform = CGAffineTransformMakeRotation(M_PI);
	}
	if (!CGAffineTransformEqualToTransform(self.view.transform, transform)) {
        __weak typeof(self)weakSelf = self;
        [UIView performAnimated:animated animation:^{
            weakSelf.view.transform = transform;
            weakSelf.view.frame = weakSelf.view.superview.bounds;
        }];
	}
}

#pragma mark - WLDeviceOrientationBroadcastReceiver

- (void)broadcaster:(WLDeviceOrientationBroadcaster *)broadcaster didChangeOrientation:(NSNumber*)orientation {
    if (self.imageView.image) {
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
        [self applyDeviceOrientation:[orientation integerValue] animated:YES];
        [self calculateScaleValues];
    }
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
