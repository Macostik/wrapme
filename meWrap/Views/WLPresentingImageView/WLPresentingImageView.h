//
//  WLPresentingImageView.h
//  meWrap
//
//  Created by Yura Granchenko on 26/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLPresentingImageView;

@protocol WLPresentingImageViewDelegate <NSObject>

- (UIView*)presentingImageView:(WLPresentingImageView *)presentingImageView dismissingViewForCandy:(WLCandy *)candy;

@end

@interface WLPresentingImageView : UIView

@property (weak, nonatomic) id <WLPresentingImageViewDelegate> delegate;

+ (instancetype)sharedPresenting;

- (void)presentCandy:(WLCandy *)candy fromView:(UIView*)view success:(void (^) (WLPresentingImageView *presetingImageView))success failure:(WLFailureBlock)failure;

- (void)dismissCandy:(WLCandy *)candy;

@end
