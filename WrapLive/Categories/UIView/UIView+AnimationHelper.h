//
//  UIView+AnimationHelper.h
//  WrapLive
//
//  Created by Sergey Maximenko on 6/5/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (AnimationHelper)

+ (void)performAnimated:(BOOL)animated animation:(void (^)(void))animation;

@end
