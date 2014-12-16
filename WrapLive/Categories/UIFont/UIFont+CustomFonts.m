//
//  UIFont+CustomFonts.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIFont+CustomFonts.h"

/* 
 Phone:
 xsmall => 11pt
 smaller => 13pt
 small => 15pt
 normal => 17pt
 large => 19pt
 larger => 21 pt
 xlarge => 23 pt
 Tablet:
 xsmall => 13pt
 smaller => 15pt
 small => 17pt
 normal => 19pt
 large => 21pt
 larger => 23 pt
 xlarge => 25 pt
 */

@implementation UIFont (CustomFonts)

+ (CGFloat)sizeWithPreset:(WLFontPreset)preset {
    UIScreen *screen = [UIScreen mainScreen];
    if (screen.bounds.size.width * screen.scale < 1080) {
        switch (preset) {
            case WLFontPresetXSmall:    return 11;
            case WLFontPresetSmaller:   return 13;
            case WLFontPresetSmall:     return 15;
            case WLFontPresetNormal:    return 17;
            case WLFontPresetLarge:     return 19;
            case WLFontPresetLarger:    return 21;
            case WLFontPresetXLarge:    return 23;
            default: return 17;
        }
    } else {
        switch (preset) {
            case WLFontPresetXSmall:    return 13;
            case WLFontPresetSmaller:   return 15;
            case WLFontPresetSmall:     return 17;
            case WLFontPresetNormal:    return 19;
            case WLFontPresetLarge:     return 21;
            case WLFontPresetLarger:    return 23;
            case WLFontPresetXLarge:    return 25;
            default: return 19;
        }
    }
}

+ (UIFont*)fontWithName:(NSString *)fontName preset:(WLFontPreset)preset {
	return [self fontWithName:fontName size:[self sizeWithPreset:preset]];
}

+ (CGFloat)preferredSizeWithPreset:(WLFontPreset)preset {
    NSString *category = [UIApplication sharedApplication].preferredContentSizeCategory;
    CGFloat difference = 0;
    if ([category isEqualToString:UIContentSizeCategoryExtraSmall]) {
        difference = -3;
    } else if ([category isEqualToString:UIContentSizeCategorySmall]) {
        difference = -2;
    } else if ([category isEqualToString:UIContentSizeCategoryMedium]) {
        difference = -1;
    } else if ([category isEqualToString:UIContentSizeCategoryLarge]) {
        difference = 0;
    } else if ([category isEqualToString:UIContentSizeCategoryExtraLarge]) {
        difference = 1;
    } else if ([category isEqualToString:UIContentSizeCategoryExtraExtraLarge]) {
        difference = 2;
    } else if ([category isEqualToString:UIContentSizeCategoryExtraExtraExtraLarge]) {
        difference = 3;
    }
    return [self sizeWithPreset:preset] + difference;
}

+ (UIFont*)preferredFontWithName:(NSString *)fontName preset:(WLFontPreset)preset {
    return [self fontWithName:fontName size:[self preferredSizeWithPreset:preset]];
}

- (UIFont*)fontWithPreset:(WLFontPreset)preset {
	UIFont* font = [UIFont fontWithName:self.fontName preset:preset];
    return font ? : self;
}

- (UIFont *)preferredFontWithPreset:(WLFontPreset)preset {
    UIFont* font = [UIFont preferredFontWithName:self.fontName preset:preset];
    return font ? : self;
}

@end
