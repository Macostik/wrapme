//
//  PGProgressBar.m
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 6/21/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLProgressBar.h"
#import "UIColor+CustomColors.h"
#import "UIView+Shorthand.h"

@interface WLProgressBar ()

@end

@implementation WLProgressBar

+ (Class)layerClass {
    return [CAShapeLayer class];
}

- (void)awakeFromNib{
    [super awakeFromNib];
    self.clipsToBounds = YES;
	[self setup];
}

- (void)setup {
    CAShapeLayer *layer = (id)self.layer;
    layer.masksToBounds = YES;
    layer.rasterizationScale = [UIScreen mainScreen].scale;
    layer.shouldRasterize = YES;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = [UIColor WL_orangeColor].CGColor;
    layer.strokeStart = layer.strokeEnd = 0.0f;
    CGSize size = self.bounds.size;
    UIBezierPath *path = [UIBezierPath bezierPath];
    if (size.width > size.height) {
        layer.lineWidth = 4;
        [path moveToPoint:CGPointMake(0, size.height/2.0f)];
        [path addLineToPoint:CGPointMake(size.width, size.height/2.0f)];
    } else {
        layer.lineWidth = 2;
        [path addArcWithCenter:CGPointMake(size.width/2.0f, size.height/2.0f)
                        radius:size.width/2 - 1
                    startAngle:-M_PI_2
                      endAngle:3*M_PI/2
                     clockwise:YES];
    }
    layer.path = path.CGPath;
}

- (void)setProgress:(float)progress {
	[self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
	progress = Smoothstep(0, 1, progress);
    if (_progress != progress) {
        float difference = ABS(progress - _progress);
        _progress = progress;
        [self updateProgress:difference animated:animated];
    }
}

- (void)updateProgress:(float)difference animated:(BOOL)animated {
    CAShapeLayer * layer = (id)self.layer;
    if (animated) {
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.duration = difference;
        [animation setFromValue:@([(layer.presentationLayer?:layer) strokeEnd])];
        [animation setToValue:@(_progress)];
        [layer removeAllAnimations];
        [layer addAnimation:animation forKey:nil];
    } else {
        [layer removeAllAnimations];
    }
    layer.strokeEnd = _progress;
}

@end
