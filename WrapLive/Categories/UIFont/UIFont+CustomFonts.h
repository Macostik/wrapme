//
//  UIFont+CustomFonts.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString* WLFontOpenSansRegular = @"OpenSans";
static NSString* WLFontOpenSansLight = @"OpenSans-Light";
static NSString* WLFontOpenSansBold = @"OpenSans-Bold";

typedef NS_ENUM(NSUInteger, WLFontPreset) {
    WLFontPresetXSmall,
    WLFontPresetSmaller,
    WLFontPresetSmall,
    WLFontPresetNormal,
    WLFontPresetLarge,
    WLFontPresetLarger,
    WLFontPresetXLarge,
};

@interface UIFont (CustomFonts)

+ (CGFloat)sizeWithPreset:(WLFontPreset)preset;

+ (UIFont*)fontWithName:(NSString *)fontName preset:(WLFontPreset)preset;

+ (CGFloat)preferredSizeWithPreset:(WLFontPreset)preset;

+ (UIFont*)preferredFontWithName:(NSString *)fontName preset:(WLFontPreset)preset;

- (UIFont*)fontWithPreset:(WLFontPreset)preset;

- (UIFont*)preferredFontWithPreset:(WLFontPreset)preset;

@end
