//
//  WLTriangleView.m
//  WrapLive
//
//  Created by Yura Granchenko on 28/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLTriangleView.h"

@implementation WLTriangleView

- (void)layoutSubviews {
    CGRect rect = self.bounds;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    if (self.contentMode == UIViewContentModeTop) {
        [path moveToPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect))];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
        [path addLineToPoint:CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect))];
        [path addLineToPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect))];
    } else {
        [path moveToPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect))];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))];
        [path addLineToPoint:CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect))];
        [path addLineToPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect))];
    }
    
    CAShapeLayer* shape = [[CAShapeLayer alloc] init];
    [shape setPath:path.CGPath];
    shape.frame = self.bounds;
    self.layer.mask = shape;
}

@end
