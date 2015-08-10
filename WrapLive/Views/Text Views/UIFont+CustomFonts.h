//
//  UIFont+CustomFonts.h
//  moji
//
//  Created by Ravenpod on 24.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString* WLDefaultSystemLightFont = @"HelveticaNeue-Light";

static NSString *WLFontPresetXSmall = @"xsmall";
static NSString *WLFontPresetSmaller = @"smaller";
static NSString *WLFontPresetSmall = @"small";
static NSString *WLFontPresetNormal = @"normal";
static NSString *WLFontPresetLarge = @"large";
static NSString *WLFontPresetLarger = @"larger";
static NSString *WLFontPresetXLarge = @"xlarge";

@interface UIFont (CustomFonts)

+ (CGFloat)sizeWithPreset:(NSString *)preset;

+ (UIFont*)fontWithName:(NSString *)fontName preset:(NSString *)preset;

+ (CGFloat)preferredSizeWithPreset:(NSString *)preset;

+ (UIFont*)preferredFontWithName:(NSString *)fontName preset:(NSString *)preset;

+ (UIFont*)preferredDefaultFontWithPreset:(NSString *)preset;

+ (UIFont*)preferredDefaultLightFontWithPreset:(NSString *)preset;

- (UIFont*)fontWithPreset:(NSString *)preset;

- (UIFont*)preferredFontWithPreset:(NSString *)preset;

@end
