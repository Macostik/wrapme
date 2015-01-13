//
//  WLGradientView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLGradientView.h"

@interface WLGradientView ()

@property (nonatomic, readonly, retain) CAGradientLayer *layer;

@end

@implementation WLGradientView

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CAGradientLayer *layer = self.layer;
        [layer setShouldRasterize:YES];
        [layer setRasterizationScale:[UIScreen mainScreen].scale];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
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

- (void)setColor:(UIColor *)color {
    _color = color;
    self.layer.colors = @[(id)color.CGColor,(id)[color colorWithAlphaComponent:0].CGColor];
}

@end
