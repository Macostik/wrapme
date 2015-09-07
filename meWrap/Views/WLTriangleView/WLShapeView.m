//
//  WLShapeView.m
//  meWrap
//
//  Created by Ravenpod on 6/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLShapeView.h"

@implementation WLShapeView

- (void)layoutSubviews {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    [self defineShapePath:path contentMode:self.contentMode];
    
    CAShapeLayer* shape = [[CAShapeLayer alloc] init];
    [shape setPath:path.CGPath];
    shape.frame = self.bounds;
    self.layer.mask = shape;
}

- (void)defineShapePath:(UIBezierPath*)path contentMode:(UIViewContentMode)contentMode {
    
}

@end
