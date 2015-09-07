//
//  UIView+AnimationHelper.h
//  meWrap
//
//  Created by Ravenpod on 6/5/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (AnimationHelper)

+ (void)performAnimated:(BOOL)animated animation:(void (^)(void))animation;

- (void)setAlpha:(CGFloat)alpha animated:(BOOL)animated;

- (void)setTransform:(CGAffineTransform)transform animated:(BOOL)animated;

- (void)setBackgroundColor:(UIColor *)backgroundColor animated:(BOOL)animated;

@end
