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
//    [self applyDeviceOrientation:[UIDevice currentDevice].orientation animated:NO];
}

- (void)setup:(WLCandy *)candy {
    __weak typeof(self)weakSelf = self;
    self.spinner.hidden = NO;
    [self.imageView setUrl:candy.picture.large success:^(UIImage *image, BOOL cached) {
        if (image) {
//            [weakSelf applyDeviceOrientation:[UIDevice currentDevice].orientation animated:NO]
            [weakSelf calculateScaleValues];
        }
        weakSelf.scrollView.userInteractionEnabled = YES;
        weakSelf.errorLabel.hidden = YES;
        self.spinner.hidden = YES;
    } failure:^(NSError *error) {
        if ([error isNetworkError]) {
            weakSelf.errorLabel.hidden = NO;
        } else {
            weakSelf.errorLabel.hidden = YES;
            self.spinner.hidden = YES;
            weakSelf.imageView.contentMode = UIViewContentModeCenter;
            weakSelf.imageView.image = [UIImage imageNamed:@"ic_photo_placeholder"];
        }
    }];
}

- (void)calculateScaleValues {
    CGFloat minimumZoomScale = CGSizeScaleToFitSize(self.size, self.imageView.image.size);
    if (minimumZoomScale <= 0) minimumZoomScale = 0.01;
    self.scrollView.maximumZoomScale = minimumZoomScale < 1 ? 2 : (minimumZoomScale + 2);
    self.scrollView.minimumZoomScale = minimumZoomScale;
    self.scrollView.zoomScale  = minimumZoomScale;
}

#pragma mark - WLDeviceOrientationBroadcastReceiver

- (void)broadcaster:(WLDeviceOrientationBroadcaster *)broadcaster didChangeOrientation:(NSNumber*)orientation {
    if (self.imageView.image) {
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
        [self calculateScaleValues];
    }
}

@end
