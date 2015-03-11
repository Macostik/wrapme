//
//  WLImageViewCell.m
//  WrapLive
//
//  Created by Yura Granchenko on 26/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLImageViewCell.h"
#import "WLImageView.h"
#import "WLDeviceOrientationBroadcaster.h"
#import "UIView+AnimationHelper.h"
#import "UIView+Shorthand.h"
#import "WLCandy+Extended.h"
#import "NSError+WLAPIManager.h"
#import "WLButton.h"

@interface WLImageViewCell () <UIScrollViewDelegate, WLDeviceOrientationBroadcastReceiver>

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

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
        CGFloat minimumZoomScale = CGSizeScaleToFitSize(self.size, image.size);
        if (minimumZoomScale <= 0) minimumZoomScale = 0.01;
        self.scrollView.maximumZoomScale = minimumZoomScale < 1 ? 2 : (minimumZoomScale + 2);
        self.scrollView.minimumZoomScale = minimumZoomScale;
        self.scrollView.zoomScale  = minimumZoomScale;
    }
}

#pragma mark - WLDeviceOrientationBroadcastReceiver

- (void)broadcaster:(WLDeviceOrientationBroadcaster *)broadcaster didChangeOrientation:(NSNumber*)orientation {
    if (self.imageView.image) {
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
        [self calculateScaleValues];
    }
}

@end
