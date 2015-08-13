//
//  UIColor+CustomColors.m
//  moji
//
//  Created by Ravenpod on 13.08.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "UIColor+CustomColors.h"
#import "NSString+Additions.h"

@implementation UIColor (CustomColors)

+ (instancetype)r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b a:(CGFloat)a {
    return [self colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f];
}

+ (instancetype)r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b {
    return [self r:r g:g b:b a:1.0f];
}

+ (instancetype)gray:(CGFloat)value {
    return [self r:value g:value b:value];
}

+ (instancetype)WL_grayDarker {
    return [self colorWithHex:0x222222];
}

+ (instancetype)WL_grayDark {
    return [self colorWithHex:0x333333];
}

+ (instancetype)WL_gray {
    return [self colorWithHex:0x555555];
}

+ (instancetype)WL_grayLight {
    return [self colorWithHex:0x777777];
}

+ (instancetype)WL_grayLighter {
    return [self colorWithHex:0x999999];
}

+ (instancetype)WL_grayLightest {
    return [self colorWithHex:0xeeeeee];
}

+ (instancetype)WL_orangeDarker {
    return [self colorWithHex:0xa13e00];
}

+ (instancetype)WL_orangeDark {
    return [self colorWithHex:0xcb5309];
}

+ (instancetype)WL_orange {
    return [self colorWithHex:0xf37526];
}

+ (instancetype)WL_orangeLight {
    return [self colorWithHex:0xff9350];
}

+ (instancetype)WL_orangeLighter {
    return [self colorWithHex:0xffac79];
}

+ (instancetype)WL_dangerRed {
    return [self colorWithHex:0xd9534f];
}

+ (instancetype)colorWithHexString:(NSString *)str {
    if (str.nonempty) {
        const char *cStr = [str cStringUsingEncoding:NSASCIIStringEncoding];
        UInt32 x = (UInt32)strtol(cStr+1, NULL, 16);
        return [self colorWithHex:x];
    }
    return nil;
}

+ (instancetype)colorWithHex:(UInt32)col {
    unsigned char b = col & 0xFF;
    unsigned char g = (col >> 8) & 0xFF;
    unsigned char r = (col >> 16) & 0xFF;
    return [self colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
}

- (instancetype)colorByAddingValue:(CGFloat)value {
    CGFloat r, g, b, a;
    if ([self getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:Smoothstep(0.0f, 1.0f, r + value)
                               green:Smoothstep(0.0f, 1.0f, g + value)
                                blue:Smoothstep(0.0f, 1.0f, b + value)
                               alpha:a];
    return nil;
}

- (instancetype)lighterColor {
	return [self colorByAddingValue:0.2f];
}

- (instancetype)darkerColor {
    return [self colorByAddingValue:-0.2f];
}

@end
