//
//  UIFont+CustomFonts.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString* WLFontNameOpenSansRegular = @"OpenSans-Regular";
static NSString* WLFontNameOpenSansLight = @"OpenSans-Light";

static CGFloat WLFontSizeMicro = 12.0f;
static CGFloat WLFontSizeSmall = 14.0f;
static CGFloat WLFontSizeNormal = 18.0f;
static CGFloat WLFontSizeLarge = 22.0f;

typedef NS_ENUM(NSUInteger, WLFontType) {
	WLFontTypeOpenSansLight = 100,
	WLFontTypeOpenSansRegular,
};

@interface UIFont (CustomFonts)

+ (UIFont*)fontWithType:(WLFontType)type size:(CGFloat)size;

- (UIFont*)fontWithType:(WLFontType)type;

+ (UIFont*)lightFontOfSize:(CGFloat)size;

+ (UIFont*)lightMicroFont;

+ (UIFont*)lightSmallFont;

+ (UIFont*)lightNormalFont;

+ (UIFont*)lightLargeFont;

+ (UIFont*)regularFontOfSize:(CGFloat)size;

+ (UIFont*)regularMicroFont;

+ (UIFont*)regularSmallFont;

+ (UIFont*)regularNormalFont;

+ (UIFont*)regularLargeFont;

@end
