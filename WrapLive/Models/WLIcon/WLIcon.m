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
                      WLIconPresetLarge:@(44),
                      WLIconPresetLarger:@(66),
                      WLIconPresetXLarge:@(88),
                      WLIconPresetLargest:@(110)};
        } else {
            sizes = @{WLIconPresetBase:@(44),
                      WLIconPresetLarge:@(66),
                      WLIconPresetLarger:@(88),
                      WLIconPresetXLarge:@(110),
                      WLIconPresetLargest:@(132)};
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
