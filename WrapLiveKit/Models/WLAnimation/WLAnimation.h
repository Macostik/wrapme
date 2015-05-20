//
//  WLAnimation.h
//  wrapLive
//
//  Created by Sergey Maximenko on 5/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLAnimation;

typedef void (^WLAnimationBlock) (WLAnimation *animation, UIView *view);

@interface WLAnimation : NSObject

@property (nonatomic, readonly) BOOL animating;

@property (weak, nonatomic) UIView *view;

@property (nonatomic) NSTimeInterval duration;

@property (nonatomic, readonly) NSTimeInterval progress;

@property (nonatomic, readonly) CGFloat progressRatio;

@property (strong, nonatomic) WLAnimationBlock animationBlock;

@property (strong, nonatomic) WLBlock completionBlock;

+ (instancetype)animationWithDuration:(NSTimeInterval)duration;

- (void)start;

@end
