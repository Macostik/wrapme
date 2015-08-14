//
//  UIColor+CustomColors.m
//  moji
//
//  Created by Ravenpod on 13.08.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "UIColor+CustomColors.h"
#import "NSString+Additions.h"

WLColorCollection *WLColors = nil;

__attribute__((constructor))
static void WLCreateColors() {
    WLColorCollection *collection = [[WLColorCollection alloc] init];
    collection.grayDarker = [UIColor colorWithHex:0x222222];
    collection.grayDark = [UIColor colorWithHex:0x333333];
    collection.gray = [UIColor colorWithHex:0x555555];
    collection.grayLight = [UIColor colorWithHex:0x777777];
    collection.grayLighter = [UIColor colorWithHex:0x999999];
    collection.grayLightest = [UIColor colorWithHex:0xeeeeee];
    collection.orangeDarker = [UIColor colorWithHex:0xa13e00];
    collection.orangeDark = [UIColor colorWithHex:0xcb5309];
    collection.orange = [UIColor colorWithHex:0xf37526];
    collection.orangeLight = [UIColor colorWithHex:0xff9350];
    collection.orangeLighter = [UIColor colorWithHex:0xffac79];
    collection.dangerRed = [UIColor colorWithHex:0xd9534f];
    WLColors = collection;
}

@implementation WLColorCollection @end

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
    return [self r:(float)r g:(float)g b:(float)b];
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
