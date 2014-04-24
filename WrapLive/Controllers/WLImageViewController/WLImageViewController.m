//
//  WLImageViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 23.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLImageViewController.h"
#import "UIImageView+ImageLoading.h"
#import "WLCandy.h"
#import "UIView+Shorthand.h"
#import "WLSupportFunctions.h"

@interface WLImageViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation WLImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.scrollView.userInteractionEnabled = NO;
	__weak typeof(self)weakSelf = self;
	[self.imageView setImageUrl:self.image.picture.large completion:^(UIImage *image, BOOL cached) {
		if (image) {
			[weakSelf configureScrollViewWithImage:image];
		}
		[weakSelf.spinner removeFromSuperview];
		weakSelf.scrollView.userInteractionEnabled = YES;
	}];
}

- (void)configureScrollViewWithImage:(UIImage*)image {
	CGSize imageSize = CGSizeMake(image.size.width*image.scale, image.size.height*image.scale);
	self.scrollView.contentSize = imageSize;
	self.scrollView.maximumZoomScale = imageSize.width / CGSizeThatFitsSize(self.view.size, imageSize).width;
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
