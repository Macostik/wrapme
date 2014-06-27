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
#import "WLSupportFunctions.h"
#import "WLDeviceOrientationBroadcaster.h"
#import "NSError+WLAPIManager.h"

@interface WLImageViewController () <UIScrollViewDelegate, WLDeviceOrientationBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
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
	[self.imageView setUrl:self.image.picture.large completion:^(UIImage *image, BOOL cached, NSError* error) {
		if (image) {
			[weakSelf configureScrollViewWithImage:image];
		}
		[weakSelf.spinner removeFromSuperview];
		weakSelf.scrollView.userInteractionEnabled = YES;
		weakSelf.errorLabel.hidden = ![error isNetworkError];
	}];
	
    [[WLDeviceOrientationBroadcaster broadcaster] addReceiver:self];
	[self applyDeviceOrientation:[UIDevice currentDevice].orientation animated:NO];
}

- (void)configureScrollViewWithImage:(UIImage*)image {
	CGSize imageSize = CGSizeMake(image.size.width*image.scale, image.size.height*image.scale);
	self.scrollView.maximumZoomScale = imageSize.width / CGSizeThatFitsSize(self.view.size, imageSize).width;
}

- (void)applyDeviceOrientation:(UIDeviceOrientation)orientation animated:(BOOL)animated {
	CGAffineTransform transform = self.scrollView.transform;
	if (orientation == UIDeviceOrientationLandscapeLeft) {
		transform = CGAffineTransformMakeRotation(M_PI_2);
	} else if (orientation == UIDeviceOrientationLandscapeRight) {
		transform = CGAffineTransformMakeRotation(3*M_PI_2);
	} else if (orientation == UIDeviceOrientationPortrait) {
		transform = CGAffineTransformIdentity;
	} else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
		transform = CGAffineTransformMakeRotation(M_PI);
	}
	if (!CGAffineTransformEqualToTransform(self.scrollView.transform, transform)) {
		if (animated) {
			[UIView beginAnimations:nil context:nil];
		}
		self.scrollView.transform = transform;
		self.scrollView.frame = self.view.bounds;
		self.errorLabel.transform = transform;
		if (animated) {
			[UIView commitAnimations];
		}
	}
}

#pragma mark - WLDeviceOrientationBroadcastReceiver

- (void)broadcaster:(WLDeviceOrientationBroadcaster *)broadcaster didChangeOrientation:(NSNumber*)orientation {
	self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
	[self applyDeviceOrientation:[orientation integerValue] animated:YES];
	self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.imageView;
}

@end
