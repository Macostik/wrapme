//
//  UIFont+CustomFonts.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLFontPresetter.h"

static NSString* WLFontOpenSansRegular = @"OpenSans";
static NSString* WLFontOpenSansLight = @"OpenSans-Light";
static NSString* WLFontOpenSansBold = @"OpenSans-Bold";

static NSString *WLFontPresetXSmall = @"xsmall";
static NSString *WLFontPresetSmaller = @"smaller";
static NSString *WLFontPresetSmall = @"small";
static NSString *WLFontPresetNormal = @"normal";
static NSString *WLFontPresetLarge = @"large";
static NSString *WLFontPresetLarger = @"largeer";
static NSString *WLFontPresetXLarge = @"xlarge";

@interface UIFont (CustomFonts)

+ (CGFloat)sizeWithPreset:(NSString *)preset;

+ (UIFont*)fontWithName:(NSString *)fontName preset:(NSString *)preset;

+ (CGFloat)preferredSizeWithPreset:(NSString *)preset;

+ (UIFont*)preferredFontWithName:(NSString *)fontName preset:(NSString *)preset;

- (UIFont*)fontWithPreset:(NSString *)preset;

- (UIFont*)preferredFontWithPreset:(NSString *)preset;

@end

@protocol WLFontCustomizing <NSObject, WLFontPresetterReceiver>

@property (nonatomic) NSString *preset;

@end
