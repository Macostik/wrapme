//
//  UIColor+CustomColors.h
//  PressGram-iOS
//
//  Created by Sergey Maximenko on 13.08.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (CustomColors)

+ (UIColor*)r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b a:(CGFloat)a;

+ (UIColor*)r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b;

+ (UIColor*)gray:(CGFloat)value;

+ (UIColor*)WL_orangeColor;

+ (UIColor*)WL_grayDarker;

+ (UIColor*)WL_grayDark;

+ (UIColor*)WL_gray;

+ (UIColor*)WL_grayLight;

+ (UIColor*)WL_grayLighter;

+ (UIColor*)WL_grayLightest;

+ (UIColor *)colorWithHexString:(NSString *)str;

- (UIColor *)colorByAddingValue:(CGFloat)value;

- (UIColor *)lighterColor;

- (UIColor *)darkerColor;

@end
