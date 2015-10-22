//
//  PGFocusAnimationView.m
//  meWrap
//
//  Created by Nikolay Rybalko on 7/10/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLCameraAdjustmentView.h"
#import "UIColor+CustomColors.h"

@interface WLCameraAdjustmentView ()

@end

@implementation WLCameraAdjustmentView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGRectInset(self.bounds, 5.0f, 5.0f)];
    path.lineWidth = 1.0f;
    
    UIColor* color = [WLColors.orange colorWithAlphaComponent:0.5f];
    
    [color set];
    
    [path stroke];
}

@end
