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

typedef NS_ENUM(NSUInteger, WLFontType) {
	WLFontTypeOpenSansRegular = 100,
	WLFontTypeOpenSansLight,
};

@interface UIFont (CustomFonts)

+ (UIFont*)fontWithType:(WLFontType)type size:(CGFloat)size;

- (UIFont*)fontWithType:(WLFontType)type;

@end
