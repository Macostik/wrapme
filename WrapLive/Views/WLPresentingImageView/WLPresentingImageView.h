//
//  WLPresentingImageView.h
//  WrapLive
//
//  Created by Yura Granchenko on 26/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLPresentingImageView;

@protocol WLPresentingImageViewDelegate <NSObject>

- (CGRect)presentingImageView:(WLPresentingImageView *)presentingImageView frameForCandy:(WLCandy *)candy;

@end

@interface WLPresentingImageView : UIView

@property (weak, nonatomic) id <WLPresentingImageViewDelegate> delegate;

+ (instancetype)sharedPresenting;

+ (instancetype)presentingCandy:(WLCandy *)candy completion:(WLBooleanBlock)completion;
- (instancetype)presentingCandy:(WLCandy *)candy completion:(WLBooleanBlock)completion;

- (void)dismissCandy:(WLCandy *)candy;

- (void)setImageUrl:(NSString *)url;

@end
