//
//  PGProgressBar.m
//  meWrap
//
//  Created by Nikolay Rybalko on 6/21/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLProgressBar.h"

@interface WLProgressBar ()

@property (strong, nonatomic) CABasicAnimation* animation;
@property (nonatomic, assign) IBInspectable CGFloat lineWidth;
@property (nonatomic) CGSize renderedSize;

@end

@implementation WLProgressBar

+ (Class)layerClass {
    return [CAShapeLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
	[self setup];
}

- (void)setup {
    self.clipsToBounds = YES;
    CAShapeLayer *layer = (id)self.layer;
    layer.masksToBounds = YES;
    layer.rasterizationScale = [UIScreen mainScreen].scale;
    layer.shouldRasterize = YES;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = Color.orange.CGColor;
    layer.strokeStart = layer.strokeEnd = 0.0f;
    [self updatePath];
    layer.actions = @{@"strokeEnd":[NSNull null]};
}

- (void)updatePathIfNeeded {
    if (!CGSizeEqualToSize(self.renderedSize, self.bounds.size)) {
        [self updatePath];
    }
}

- (void)updatePath {
    CAShapeLayer *layer = (id)self.layer;
    CGSize size = self.bounds.size;
    UIBezierPath *path = [UIBezierPath bezierPath];
    if (size.width > size.height) {
        layer.lineWidth = self.lineWidth > 0 ? self.lineWidth : 4;
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
    self.renderedSize = size;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updatePathIfNeeded];
}

- (void)setProgress:(float)progress {
	[self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
	progress = Smoothstep(0, 1, progress);
    if (_progress != progress) {
        _progress = progress;
        [self updateProgress:animated];
    }
}

- (CABasicAnimation *)animation {
    if (!_animation) {
        _animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    }
    return _animation;
}

- (void)updateProgress:(BOOL)animated {
    static NSString* animationKey = @"strokeAnimation";
    CAShapeLayer * layer = (id)self.layer;
    if (animated) {
        CABasicAnimation* animation = self.animation;
        CGFloat fromValue = [(layer.presentationLayer?:layer) strokeEnd];
        animation.duration = ABS(_progress - fromValue);
        [animation setFromValue:@(fromValue)];
        [animation setToValue:@(_progress)];
        [layer removeAnimationForKey:animationKey];
        layer.strokeEnd = _progress;
        [layer addAnimation:animation forKey:animationKey];
    } else {
        [layer removeAnimationForKey:animationKey];
        layer.strokeEnd = _progress;
    }
}

@end
