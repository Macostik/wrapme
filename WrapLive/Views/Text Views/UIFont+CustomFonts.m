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

+ (CGFloat)sizeWithPreset:(NSString *)preset {
    static NSDictionary *sizes = nil;
    if (!sizes) {
        UIScreen *screen = [UIScreen mainScreen];
        if (screen.bounds.size.width * screen.scale < 1080) {
            sizes = @{WLFontPresetXSmall:@(11),
                      WLFontPresetSmaller:@(13),
                      WLFontPresetSmall:@(15),
                      WLFontPresetNormal:@(17),
                      WLFontPresetLarge:@(19),
                      WLFontPresetLarger:@(21),
                      WLFontPresetXLarge:@(23)};
        } else {
            sizes = @{WLFontPresetXSmall:@(13),
                      WLFontPresetSmaller:@(15),
                      WLFontPresetSmall:@(17),
                      WLFontPresetNormal:@(19),
                      WLFontPresetLarge:@(21),
                      WLFontPresetLarger:@(23),
                      WLFontPresetXLarge:@(25)};
        }
    }
    return [[sizes objectForKey:preset] floatValue];
}

+ (UIFont*)fontWithName:(NSString *)fontName preset:(NSString *)preset {
	return [self fontWithName:fontName size:[self sizeWithPreset:preset]];
}

+ (CGFloat)sizeAdjustment:(NSString*)category {
    static NSDictionary *adjustments = nil;
    if (!adjustments) {
        adjustments = @{UIContentSizeCategoryExtraSmall:@(-3),
                        UIContentSizeCategorySmall:@(-2),
                        UIContentSizeCategoryMedium:@(-1),
                        UIContentSizeCategoryLarge:@(0),
                        UIContentSizeCategoryExtraLarge:@(1),
                        UIContentSizeCategoryExtraExtraLarge:@(2),
                        UIContentSizeCategoryExtraExtraExtraLarge:@(3)};
    }
    return [[adjustments objectForKey:category] floatValue];
}

+ (CGFloat)preferredSizeWithPreset:(NSString *)preset {
    CGFloat adjustment = [self sizeAdjustment:[UIApplication sharedApplication].preferredContentSizeCategory];
    return [self sizeWithPreset:preset] + adjustment;
}

+ (UIFont*)preferredFontWithName:(NSString *)fontName preset:(NSString *)preset {
    return [self fontWithName:fontName size:[self preferredSizeWithPreset:preset]];
}

- (UIFont*)fontWithPreset:(NSString *)preset {
	UIFont* font = [UIFont fontWithName:self.fontName preset:preset];
    return font ? : self;
}

- (UIFont *)preferredFontWithPreset:(NSString *)preset {
    UIFont* font = [UIFont preferredFontWithName:self.fontName preset:preset];
    return font ? : self;
}

@end
