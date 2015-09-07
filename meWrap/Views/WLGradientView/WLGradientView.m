//
//  WLGradientView.m
//  meWrap
//
//  Created by Ravenpod on 1/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLGradientView.h"

@interface WLGradientView ()

@property (nonatomic, readonly, retain) CAGradientLayer *layer;

@end

@implementation WLGradientView

@dynamic layer;

@synthesize endColor = _endColor;

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _endLocation = NSINTEGER_DEFINED;
        CAGradientLayer *layer = self.layer;
        [layer setShouldRasterize:YES];
        [layer setRasterizationScale:[UIScreen mainScreen].scale];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _endLocation = NSINTEGER_DEFINED;
        CAGradientLayer *layer = self.layer;
        [layer setShouldRasterize:YES];
        [layer setRasterizationScale:[UIScreen mainScreen].scale];
    }
    return self;
}

- (void)setContentMode:(UIViewContentMode)contentMode {
    [super setContentMode:contentMode];
    CAGradientLayer *layer = self.layer;
    switch (contentMode) {
        case UIViewContentModeTop:
            layer.startPoint = CGPointMake(0.5, 0);
            layer.endPoint = CGPointMake(0.5, 1);
            break;
        case UIViewContentModeLeft:
            layer.startPoint = CGPointMake(0, 0.5);
            layer.endPoint = CGPointMake(1, 0.5);
            break;
        case UIViewContentModeRight:
            layer.startPoint = CGPointMake(1, 0.5);
            layer.endPoint = CGPointMake(0, 0.5);
            break;
        default:
            layer.startPoint = CGPointMake(0.5, 1);
            layer.endPoint = CGPointMake(0.5, 0);
            break;
    }
}

- (void)setStartColor:(UIColor *)startColor {
    _startColor = startColor;
    self.layer.colors = @[(id)self.startColor.CGColor,(id)self.endColor.CGColor];
}

- (void)setEndColor:(UIColor *)endColor {
    _endColor = endColor;
    self.layer.colors = @[(id)self.startColor.CGColor,(id)self.endColor.CGColor];
}

- (UIColor *)endColor {
    if (!_endColor) _endColor = [_startColor colorWithAlphaComponent:0];
    return _endColor;
}

- (void)setStartLocation:(CGFloat)startLocation {
    _startLocation = startLocation;
    self.layer.locations = @[@(self.startLocation), @(self.endLocation)];
}

- (void)setEndLocation:(CGFloat)endLocation {
    _endLocation = endLocation;
    self.layer.locations = @[@(self.startLocation), @(self.endLocation)];
}

@end
