//
//  WLImageViewCell.m
//  WrapLive
//
//  Created by Yura Granchenko on 26/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLImageViewCell.h"
#import "WLDeviceOrientationBroadcaster.h"
#import "UIView+AnimationHelper.h"
#import "WLButton.h"

@interface WLImageViewCell () <UIScrollViewDelegate, WLDeviceOrientationBroadcastReceiver>

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aspectRatioConstraint;

@end

@implementation WLImageViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.scrollView.userInteractionEnabled = NO;
    [[WLDeviceOrientationBroadcaster broadcaster] addReceiver:self];
    [self.imageView setContentMode:UIViewContentModeCenter forState:WLImageViewStateFailed];
    [self.imageView setContentMode:UIViewContentModeCenter forState:WLImageViewStateEmpty];
    [self.imageView setImageName:@"ic_photo_placeholder" forState:WLImageViewStateFailed];
    [self.imageView setImageName:@"ic_photo_placeholder" forState:WLImageViewStateEmpty];
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 2;
    
    [self.scrollView.superview addGestureRecognizer:self.scrollView.panGestureRecognizer];
    [self.scrollView.superview addGestureRecognizer:self.scrollView.pinchGestureRecognizer];
}

- (void)setup:(WLCandy *)candy {
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
    }
}

#pragma mark - WLDeviceOrientationBroadcastReceiver

- (void)broadcaster:(WLDeviceOrientationBroadcaster *)broadcaster didChangeOrientation:(NSNumber*)orientation {
    self.scrollView.zoomScale = 1;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

@end
