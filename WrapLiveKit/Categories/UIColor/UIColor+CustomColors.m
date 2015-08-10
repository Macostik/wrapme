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

+ (UIColor*)r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b a:(CGFloat)a {
    return [self colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f];
}

+ (UIColor*)r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b {
    return [self r:r g:g b:b a:1.0f];
}

+ (UIColor *)gray:(CGFloat)value {
    return [self r:value g:value b:value];
}

+ (UIColor*)WL_grayDarker {
    return [UIColor colorWithHex:0x222222];
}

+ (UIColor*)WL_grayDark {
    return [UIColor colorWithHex:0x333333];
}

+ (UIColor*)WL_gray {
    return [UIColor colorWithHex:0x555555];
}

+ (UIColor*)WL_grayLight {
    return [UIColor colorWithHex:0x777777];
}

+ (UIColor*)WL_grayLighter {
    return [UIColor colorWithHex:0x999999];
}

+ (UIColor*)WL_grayLightest {
    return [UIColor colorWithHex:0xeeeeee];
}

+ (UIColor*)WL_orangeDarker {
    return [UIColor colorWithHex:0xa13e00];
}

+ (UIColor*)WL_orangeDark {
    return [UIColor colorWithHex:0xcb5309];
}

+ (UIColor *)WL_orange {
    return [UIColor colorWithHex:0xf37526];
}

+ (UIColor*)WL_orangeLight {
    return [UIColor colorWithHex:0xff9350];
}

+ (UIColor*)WL_orangeLighter {
    return [UIColor colorWithHex:0xffac79];
}

+ (UIColor *)colorWithHexString:(NSString *)str {
    if (str.nonempty) {
        const char *cStr = [str cStringUsingEncoding:NSASCIIStringEncoding];
        UInt32 x = (UInt32)strtol(cStr+1, NULL, 16);
        return [UIColor colorWithHex:x];
    }
    return nil;
}

+ (UIColor *)colorWithHex:(UInt32)col {
    unsigned char b = col & 0xFF;
    unsigned char g = (col >> 8) & 0xFF;
    unsigned char r = (col >> 16) & 0xFF;
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
}

- (UIColor *)colorByAddingValue:(CGFloat)value {
    CGFloat r, g, b, a;
    if ([self getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:Smoothstep(0.0f, 1.0f, r + value)
                               green:Smoothstep(0.0f, 1.0f, g + value)
                                blue:Smoothstep(0.0f, 1.0f, b + value)
                               alpha:a];
    return nil;
}

- (UIColor *)lighterColor {
	return [self colorByAddingValue:0.2f];
}

- (UIColor *)darkerColor {
    return [self colorByAddingValue:-0.2f];
}

@end
