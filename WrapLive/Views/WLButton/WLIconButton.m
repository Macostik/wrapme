//
//  WLIconButton.m
//  WrapLive
//
//  Created by Yura Granchenko on 27/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLIconButton.h"
#import "WLIcon.h"
#import "NSObject+Extension.h"
#import "UIColor+CustomColors.h"

@implementation WLIconButton

- (void)setIconColor:(UIColor *)iconColor {
    _iconColor = iconColor;
    [self enqueueSelectorPerforming:@selector(setup) afterDelay:0.0f];
}

- (void)setIconName:(NSString *)iconName {
    _iconName = iconName;
    [self enqueueSelectorPerforming:@selector(setup) afterDelay:0.0f];
}

- (void)setIconPreset:(NSString *)iconPreset {
    _iconPreset = iconPreset;
    [self enqueueSelectorPerforming:@selector(setup) afterDelay:0.0f];
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
    FAKIcon *icon = [WLIcon iconWithName:_iconName preset:_iconPreset color:color];
    if (icon) {
        [self setAttributedTitle:icon.attributedString forState:UIControlStateNormal];
        color = [color darkerColor];
        if (color) {
            [icon addAttribute:NSForegroundColorAttributeName value:color];
        }
        [self setAttributedTitle:icon.attributedString forState:UIControlStateHighlighted];
    }
}

@end
