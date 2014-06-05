//
//  UIView+AnimationHelper.m
//  WrapLive
//
//  Created by Sergey Maximenko on 6/5/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIView+AnimationHelper.h"

@implementation UIView (AnimationHelper)

+ (void)performAnimated:(BOOL)animated animation:(void (^)(void))animation {
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationBeginsFromCurrentState:YES];
    }
    animation();
    if (animated) {
        [UIView commitAnimations];
    }
}

@end
