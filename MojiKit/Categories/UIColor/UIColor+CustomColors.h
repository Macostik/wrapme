//
//  UIColor+CustomColors.h
//  moji
//
//  Created by Ravenpod on 13.08.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (CustomColors)

+ (instancetype)r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b a:(CGFloat)a;

+ (instancetype)r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b;

+ (instancetype)gray:(CGFloat)value;

+ (instancetype)WL_grayDarker;

+ (instancetype)WL_grayDark;

+ (instancetype)WL_gray;

+ (instancetype)WL_grayLight;

+ (instancetype)WL_grayLighter;

+ (instancetype)WL_grayLightest;

+ (instancetype)WL_orangeDarker;

+ (instancetype)WL_orangeDark;

+ (instancetype)WL_orange;

+ (instancetype)WL_orangeLight;

+ (instancetype)WL_orangeLighter;

+ (instancetype)WL_dangerRed;

+ (instancetype)colorWithHexString:(NSString *)str;

- (instancetype)colorByAddingValue:(CGFloat)value;

- (instancetype)lighterColor;

- (instancetype)darkerColor;

@end
