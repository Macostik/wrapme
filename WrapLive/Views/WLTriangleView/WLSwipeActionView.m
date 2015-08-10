//
//  WLSwipeActionView.m
//  moji
//
//  Created by Ravenpod on 6/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSwipeActionView.h"

@implementation WLSwipeActionView

- (void)defineShapePath:(UIBezierPath *)path contentMode:(UIViewContentMode)contentMode {
    CGRect rect = self.bounds;
    CGFloat height = rect.size.height;
    CGFloat width = rect.size.width;
    if (contentMode == UIViewContentModeLeft) {
        [path moveToPoint:CGPointMake(0, 0)];
        [path addLineToPoint:CGPointMake(0, height)];
        [path addLineToPoint:CGPointMake(width - height/2.0f, height)];
        [path addLineToPoint:CGPointMake(width, height/2.0f)];
        [path addLineToPoint:CGPointMake(width - height/2.0f, 0)];
        [path moveToPoint:CGPointMake(0, 0)];
    } else if (contentMode == UIViewContentModeRight) {
        [path moveToPoint:CGPointMake(width, 0)];
        [path addLineToPoint:CGPointMake(height/2.0f, 0)];
        [path addLineToPoint:CGPointMake(0, height/2.0f)];
        [path addLineToPoint:CGPointMake(height/2.0f, height)];
        [path addLineToPoint:CGPointMake(width, height)];
        [path moveToPoint:CGPointMake(width, 0)];
    }
}

@end
