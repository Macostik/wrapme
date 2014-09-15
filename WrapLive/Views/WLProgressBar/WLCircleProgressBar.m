//
//  WLCircleProgressBar.m
//  WrapLive
//
//  Created by Sergey Maximenko on 16.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCircleProgressBar.h"
#import "WLBorderView.h"
#import "UIColor+CustomColors.h"
#import "UIView+Shorthand.h"
#import "NSArray+Additions.h"
#import <AFNetworking/AFURLConnectionOperation.h>

@interface WLCircleProgressBar ()

@property (nonatomic, readonly) CAShapeLayer* progressLayer;

@end

@implementation WLCircleProgressBar

- (void)setup {
    self.progressLayer.path  = [UIBezierPath bezierPathWithArcCenter:self.centerBoundary
                                                              radius:self.width/2 - 2
                                                          startAngle:-M_PI_2
                                                            endAngle:3*M_PI/2
                                                           clockwise:YES].CGPath;
   self.progressLayer.hidden = [self isHideProgressLayer];
    
}

- (CAShapeLayer*)progressLayer {
    CAShapeLayer* progressLayer = (id)self.layer.mask;
    if (!progressLayer) {
        progressLayer = [CAShapeLayer layer];
        progressLayer.frame = self.bounds;
        progressLayer.fillColor = [UIColor clearColor].CGColor;
        progressLayer.strokeColor = [UIColor WL_orangeColor].CGColor;
        progressLayer.lineWidth = 2;
        progressLayer.strokeStart = .0f;
        self.layer.mask = progressLayer;
        self.backgroundColor = [UIColor WL_orangeColor];
    }
    
    return progressLayer;
}

- (void)updateProgressViewAnimated:(BOOL)animated difference:(float)difference {
    self.progressLayer.hidden =  [self isHideProgressLayer];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        if (_progress) {
           self.progressLayer.hidden =  [self isHideProgressLayer];
        }
    }];
    [CATransaction setAnimationDuration:animated ? ABS(difference * 2.0f) : 0];
    self.progressLayer.strokeEnd = _progress;
    [CATransaction commit];
}

- (BOOL)isHideProgressLayer {
    if (![WLInternetConnectionBroadcaster broadcaster].reachable) {
        return  NO;
    } else {
        return (self.operation == nil);
    }
}

@end
