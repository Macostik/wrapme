//
//  WLIcon.m
//  WrapLive
//
//  Created by Sergey Maximenko on 2/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLIcon.h"
#import <objc/message.h>

@implementation WLIcon

+ (CGFloat)sizeWithPreset:(NSString *)preset {
    static NSDictionary *sizes = nil;
    if (!sizes) {
        if (WLConstants.iPhone) {
            sizes = @{WLIconPresetBase:@(32),
                      WLIconPresetLarge:@(48),
                      WLIconPresetLarger:@(72),
                      WLIconPresetXLarge:@(108),
                      WLIconPresetLargest:@(162)};
        } else {
            sizes = @{WLIconPresetBase:@(48),
                      WLIconPresetLarge:@(72),
                      WLIconPresetLarger:@(108),
                      WLIconPresetXLarge:@(162),
                      WLIconPresetLargest:@(243)};
        }
    }
    return [[sizes objectForKey:preset] floatValue];
}

+ (FAKIcon *)iconWithName:(NSString *)name {
    return [self iconWithName:name preset:WLIconPresetBase];
}

+ (FAKIcon *)iconWithName:(NSString *)name preset:(NSString *)preset {
    return [self iconWithName:name preset:preset color:[UIColor whiteColor]];
}

+ (FAKIcon *)iconWithName:(NSString *)name preset:(NSString *)preset color:(UIColor *)color {
    static NSDictionary *icons = nil;
    if (!icons) {
        icons = [FAKFontAwesome allIcons];
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            didReceiveMemoryWarning(^{
                icons = nil;
            });
        });
    }
    
    NSString* code = [[icons allKeysForObject:name] lastObject];
    if (code) {
        CGFloat size = [self sizeWithPreset:preset ? : WLIconPresetBase];
        FAKIcon *icon = [FAKFontAwesome iconWithCode:code size:size];
        [icon addAttribute:NSForegroundColorAttributeName value:color ? : [UIColor whiteColor]];
        return icon;
    } else {
        return nil;
    }
}

@end
