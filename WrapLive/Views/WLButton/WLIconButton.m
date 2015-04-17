//
//  WLIconButton.m
//  WrapLive
//
//  Created by Yura Granchenko on 27/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLIconButton.h"
#import "NSObject+Extension.h"
#import "WLIcon.h"

@implementation WLIconButton

- (void)setIconColor:(UIColor *)iconColor {
    _iconColor = iconColor;
    [self setup];
}

- (void)setIconName:(NSString *)iconName {
    _iconName = iconName;
    [self setup];
}

- (void)setIconPreset:(NSString *)iconPreset {
    _iconPreset = iconPreset;
    [self setup];
}

- (instancetype)initWithFrame:(CGRect)frame iconName:(NSString *)name iconColor:(UIColor *)color preset:(NSString *)preset {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupWithName:name color:color preset:preset];
    }
    return self;
}

+ (instancetype)iconButtonWithFrame:(CGRect)frame iconName:(NSString *)name iconColor:(UIColor *)color preset:(NSString *)preset {
    return [[self alloc] initWithFrame:frame iconName:name iconColor:color preset:preset];
}

- (void)setupWithName:(NSString *)name color:(UIColor *)color preset:(NSString *)preset {
    _iconName = name;
    _iconColor = color;
    _iconPreset = preset;
    [self setup];
}

- (void)setup {
    UIColor *color = _iconColor ? : [UIColor whiteColor];
    [self setAttributedTitle:WLIconCreate(_iconName, _iconPreset, color) forState:UIControlStateNormal];
    [self setAttributedTitle:WLIconCreate(_iconName, _iconPreset, [color darkerColor]) forState:UIControlStateHighlighted];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = self.bounds.size.width/2;
    self.layer.masksToBounds = _circled;
    if (_borderWidth) {
        self.layer.borderWidth = _borderWidth;
        self.layer.borderColor = _iconColor ? _iconColor.CGColor : [UIColor whiteColor].CGColor;
    }
}

@end
