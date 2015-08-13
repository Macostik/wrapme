//
//  WLPresentingImageView.m
//  moji
//
//  Created by Yura Granchenko on 26/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPresentingImageView.h"
#import "WLNavigationHelper.h"
#import "WLCandyCell.h"

@interface WLPresentingImageView () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet WLImageView *imageView;

@end

@implementation WLPresentingImageView

+ (instancetype)sharedPresenting {
    return [WLPresentingImageView loadFromNib];
}

- (void)presentCandy:(WLCandy *)candy success:(void (^)(WLPresentingImageView *))success failure:(WLFailureBlock)failure {
    [self presentingAsMainWindowSubview];
    UIImage *image = [WLSystemImageCache imageWithIdentifier:candy.picture.large];
    if (!image) {
        image = [[WLImageCache cache] imageWithUrl:candy.picture.large];
    }
    if (!image) {
        if (failure) failure(nil);
        [self removeFromSuperview];
        return;
    }
    self.imageView.image = image;
    self.imageView.frame = [self.delegate presentImageView:self getFrameCandyCell:candy];
    
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.25
                          delay:.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         weakSelf.imageView.frame = CGRectThatFitsSize(weakSelf.size, weakSelf.imageView.image.size);
                         weakSelf.backgroundColor = [weakSelf.backgroundColor colorWithAlphaComponent:1];
                     } completion:^(BOOL finished) {
                         if (success) success(weakSelf);
                         [weakSelf removeFromSuperview];
                     }];
}

- (void)dismissCandy:(WLCandy *)candy {
    [self presentingAsMainWindowSubview];
    UIImage *image = [WLSystemImageCache imageWithIdentifier:candy.picture.large];
    if (!image) {
        image = [[WLImageCache cache] imageWithUrl:candy.picture.large];
    }
    if (!image) {
        [self removeFromSuperview];
        return;
    }
    __weak __typeof(self)weakSelf = self;
    self.imageView.image = image;
    self.imageView.frame = CGRectThatFitsSize(weakSelf.size, image.size);
    CGRect rect = [weakSelf.delegate dismissImageView:weakSelf getFrameCandyCell:candy];
    [UIView animateWithDuration:0.25
                          delay:.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         weakSelf.backgroundColor = [weakSelf.backgroundColor colorWithAlphaComponent:0];
                         weakSelf.imageView.frame = rect;
                     } completion:^(BOOL finished) {
                         [weakSelf removeFromSuperview];
                     }];
}

- (void)presentingAsMainWindowSubview {
    UIView *parentView = [UIWindow mainWindow].rootViewController.view;
    self.backgroundColor = [self.backgroundColor colorWithAlphaComponent:0];
    self.frame = parentView.frame;
    [parentView addSubview:self];
}

@end
