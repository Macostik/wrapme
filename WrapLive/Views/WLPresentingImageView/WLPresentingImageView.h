//
//  WLPresentingImageView.h
//  moji
//
//  Created by Yura Granchenko on 26/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLPresentingImageView;

@protocol WLPresentingImageViewDelegate <NSObject>

- (CGRect)presentImageView:(WLPresentingImageView *)presentingImageView getFrameCandyCell:(WLCandy *)candy;
- (CGRect)dismissImageView:(WLPresentingImageView *)presentingImageView getFrameCandyCell:(WLCandy *)candy;

@end

@interface WLPresentingImageView : UIView

@property (weak, nonatomic, readonly) WLImageView *imageView;
@property (weak, nonatomic) id <WLPresentingImageViewDelegate> delegate;

+ (instancetype)sharedPresenting;
- (instancetype)presentingCandy:(WLCandy *)candy completion:(WLBooleanBlock)completion;
- (void)dismissViewByCandy:(WLCandy *)candy completion:(WLBooleanBlock)competion;
- (void)setImageUrl:(NSString *)url;

@end
