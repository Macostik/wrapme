//
//  UIColor+CustomColors.m
//  PressGram-iOS
//
//  Created by Sergey Maximenko on 13.08.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "UIColor+CustomColors.h"
#import "WLSupportFunctions.h"

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

+ (UIColor*)WL_grayColor {
    return [self gray:153];
}

+ (UIColor*)WL_darkGrayColor {
    return [self gray:51];
}

+ (UIColor *)colorWithHexString:(NSString *)str {
    if (str.length > 0) {
        const char *cStr = [str cStringUsingEncoding:NSASCIIStringEncoding];
        long x = strtol(cStr+1, NULL, 16);
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

- (UIColor *)darkerColor
{
    return [self colorByAddingValue:-0.2f];
}

@end
