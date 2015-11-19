//
//  WLPresentingImageView.m
//  meWrap
//
//  Created by Yura Granchenko on 26/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPresentingImageView.h"

@interface WLPresentingImageView ()

@property (weak, nonatomic) IBOutlet WLImageView *imageView;

@end

@implementation WLPresentingImageView

+ (instancetype)sharedPresenting {
    return [WLPresentingImageView loadFromNib];
}

- (void)presentCandy:(Candy *)candy fromView:(UIView *)view success:(void (^)(WLPresentingImageView *))success failure:(WLFailureBlock)failure {
    [self presentingAsMainWindowSubview];
    UIImage *image = [SystemImageCache instance][candy.picture.large];
    if (!image) {
        image = [[WLImageCache defaultCache] imageWithUrl:candy.picture.large];
    }
    if (!image) {
        if (failure) failure(nil);
        [self removeFromSuperview];
        return;
    }
    self.imageView.image = image;
    
    [StreamView lock];
    self.imageView.frame = [self.superview convertRect:view.bounds fromCoordinateSpace:view];
    view.hidden = YES;
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.25
                          delay:.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         weakSelf.imageView.frame = CGRectThatFitsSize(weakSelf.size, weakSelf.imageView.image.size);
                         weakSelf.backgroundColor = [weakSelf.backgroundColor colorWithAlphaComponent:1];
                     } completion:^(BOOL finished) {
                         if (success) success(weakSelf);
                         view.hidden = NO;
                         [weakSelf removeFromSuperview];
                         [StreamView unlock];
                     }];
}

- (void)dismissCandy:(Candy *)candy {
    
    UIView *dismissingView = [self.delegate presentingImageView:self dismissingViewForCandy:candy];
    if (!dismissingView) {
        [self removeFromSuperview];
        return;
    }
    
    [self presentingAsMainWindowSubview];
    UIImage *image = [SystemImageCache instance][candy.picture.large];
    if (!image) {
        image = [[WLImageCache defaultCache] imageWithUrl:candy.picture.large];
    }
    if (!image) {
        [self removeFromSuperview];
        return;
    }
    
    self.imageView.image = image;
    self.imageView.frame = CGRectThatFitsSize(self.size, image.size);
    __weak __typeof(self)weakSelf = self;
    [StreamView lock];
    CGRect rect = [self.superview convertRect:dismissingView.bounds fromCoordinateSpace:dismissingView];
    dismissingView.hidden = YES;
    [UIView animateWithDuration:0.25
                          delay:.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         weakSelf.backgroundColor = [weakSelf.backgroundColor colorWithAlphaComponent:0];
                         weakSelf.imageView.frame = rect;
                     } completion:^(BOOL finished) {
                         dismissingView.hidden = NO;
                         [weakSelf removeFromSuperview];
                         [StreamView unlock];
                     }];
}

- (void)presentingAsMainWindowSubview {
    UIView *parentView = [UIWindow mainWindow].rootViewController.view;
    self.backgroundColor = [self.backgroundColor colorWithAlphaComponent:0];
    self.frame = parentView.frame;
    [parentView addSubview:self];
}

@end
