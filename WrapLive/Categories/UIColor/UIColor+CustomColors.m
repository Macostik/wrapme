//
//  UIColor+CustomColors.m
//  PressGram-iOS
//
//  Created by Sergey Maximenko on 13.08.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "UIColor+CustomColors.h"
#import "NSString+Additions.h"

/*
 gray-darker:  #222
 gray-dark: #333
 gray: #555
 gray-light: #777
 gray-lighter: #eee
 */

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

+ (UIColor *)WL_orangeColor {
    return [self r:243 g:117 b:38];
}

+ (UIColor*)WL_grayDarker {
    return [UIColor colorWithWhite:0.101 alpha:1.000];
}

+ (UIColor*)WL_grayDark {
    return [UIColor colorWithWhite:0.151 alpha:1.000];
}

+ (UIColor*)WL_gray {
    return [UIColor colorWithWhite:0.264 alpha:1.000];
}

+ (UIColor*)WL_grayLight {
    return [UIColor colorWithWhite:0.391 alpha:1.000];
}

+ (UIColor*)WL_grayLighter {
    return [UIColor colorWithWhite:0.917 alpha:1.000];
}

+ (UIColor *)WL_clearColor {
    return [[self r:.0f g:.0f b:.0f] colorWithAlphaComponent:.0f];
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
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
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
