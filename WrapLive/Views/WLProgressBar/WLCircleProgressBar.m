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
#import "WLInternetConnectionBroadcaster.h"
#import <AFNetworking/AFURLConnectionOperation.h>
#import <AFNetworking/AFHTTPRequestOperation.h>

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

- (void)setWaitUpload:(BOOL)waitUpload {
     _waitUpload = waitUpload;
    [self setProgress:.1 animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
    progress = Smoothstep(0, 1, progress);
     self.progressLayer.hidden = NO;
    _progress = progress;
   
    if (animated) {
        NSTimeInterval duration = 2.0f;
        [self performAnimationWithDuration:duration];
        [self performSelector:@selector(complitionAnimation) withObject:nil afterDelay:duration];
    } else {
        [self performAnimationWithDuration:0.0];
        
    }
}

- (void)performAnimationWithDuration:(NSTimeInterval)duration {
    [CATransaction begin];
    [CATransaction setAnimationDuration:duration];
    self.progressLayer.strokeEnd = _progress;
    [CATransaction commit];
}

- (void)complitionAnimation {
    self.progressLayer.hidden = YES;
}

@end
