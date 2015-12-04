//
//  WLPresentingImageView.h
//  meWrap
//
//  Created by Yura Granchenko on 26/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLPresentingImageView, Candy;

@protocol WLPresentingImageViewDelegate <NSObject>

- (UIView*)presentingImageView:(WLPresentingImageView *)presentingImageView dismissingViewForCandy:(Candy *)candy;

@end

@interface WLPresentingImageView : UIView

@property (weak, nonatomic) id <WLPresentingImageViewDelegate> delegate;

+ (instancetype)sharedPresenting;

- (void)presentCandy:(Candy *)candy fromView:(UIView*)view success:(void (^) (WLPresentingImageView *presetingImageView))success failure:(FailureBlock)failure;

- (void)dismissCandy:(Candy *)candy;

@end
