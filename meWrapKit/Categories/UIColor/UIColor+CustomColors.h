//
//  UIColor+CustomColors.h
//  meWrap
//
//  Created by Ravenpod on 13.08.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLColorCollection : NSObject

@property (strong, nonatomic) UIColor *grayDarker;

@property (strong, nonatomic) UIColor *grayDark;

@property (strong, nonatomic) UIColor *gray;

@property (strong, nonatomic) UIColor *grayLight;

@property (strong, nonatomic) UIColor *grayLighter;

@property (strong, nonatomic) UIColor *grayLightest;

@property (strong, nonatomic) UIColor *orangeDarker;

@property (strong, nonatomic) UIColor *orangeDark;

@property (strong, nonatomic) UIColor *orange;

@property (strong, nonatomic) UIColor *orangeLight;

@property (strong, nonatomic) UIColor *orangeLighter;

@property (strong, nonatomic) UIColor *orangeLightest;

@property (strong, nonatomic) UIColor *dangerRed;

@end

extern WLColorCollection *WLColors;

@interface UIColor (CustomColors)

+ (instancetype)r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b a:(CGFloat)a;

+ (instancetype)r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b;

+ (instancetype)gray:(CGFloat)value;

+ (instancetype)colorWithHexString:(NSString *)str;

+ (instancetype)colorWithHex:(UInt32)col;

- (instancetype)colorByAddingValue:(CGFloat)value;

- (instancetype)lighterColor;

- (instancetype)darkerColor;

@end
