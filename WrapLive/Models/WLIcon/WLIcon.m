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

+ (UIFont *)iconFontWithSize:(CGFloat)size {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self registerIconFontWithURL:[[NSBundle mainBundle] URLForResource:@"wrapliveicons" withExtension:@"ttf"]];
    });
    return [UIFont fontWithName:@"wrapliveicons" size:size];
}

+ (CGFloat)sizeWithPreset:(NSString *)preset {
    static NSDictionary *sizes = nil;
    if (!sizes) {
        if (WLConstants.iPhone) {
            sizes = @{WLIconPresetSmaller:@(14),
                      WLIconPresetSmall:@(18),
                      WLIconPresetBase:@(24),
                      WLIconPresetNormal:@(36),
                      WLIconPresetLarge:@(40),
                      WLIconPresetLarger:@(48),
                      WLIconPresetXLarge:@(72),
                      WLIconPresetLargest:@(96)};
        } else {
            sizes = @{WLIconPresetSmaller:@(14),
                      WLIconPresetSmall:@(24),
                      WLIconPresetBase:@(36),
                      WLIconPresetNormal:@(46),
                      WLIconPresetLarge:@(54),
                      WLIconPresetLarger:@(72),
                      WLIconPresetXLarge:@(108),
                      WLIconPresetLargest:@(144)};
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
    
    static NSMapTable *icons = nil;
    if (!icons) {
        icons = [NSMapTable strongToStrongObjectsMapTable];
        [icons setObject:[[self allIcons] dictionaryBySwappingObjectsAndKeys] forKey:self];
        [icons setObject:[[FAKFontAwesome allIcons] dictionaryBySwappingObjectsAndKeys] forKey:[FAKFontAwesome class]];
        [icons setObject:[[FAKIonIcons allIcons] dictionaryBySwappingObjectsAndKeys] forKey:[FAKIonIcons class]];
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            didReceiveMemoryWarning(^{
                icons = nil;
            });
        });
    }
    
    for (Class fontClass in icons) {
        NSString *code = [[icons objectForKey:fontClass] objectForKey:name];
        if (code) {
            CGFloat size = [self sizeWithPreset:preset ? : WLIconPresetBase];
            FAKIcon *icon = [fontClass iconWithCode:code size:size];
            [icon addAttribute:NSForegroundColorAttributeName value:color ? : [UIColor whiteColor]];
            return icon;
        }
    }
    
    return nil;
}

+ (NSDictionary *)allIcons {
    return @{@"a":@"wl-circleCandy",@"e":@"wl-candy",@"b":@"wl-flashOn",@"c":@"wl-flashAuto",@"d":@"wl-flashOff", @"f":@"wl-calendar"};
}

@end
