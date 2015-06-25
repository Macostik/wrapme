//
//  WLIcon.m
//  WrapLive
//
//  Created by Sergey Maximenko on 2/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLIcon.h"
#import <objc/message.h>
#import <CoreText/CoreText.h>

@implementation WLIcon

+ (CGFloat)sizeWithPreset:(NSString *)preset {
    static NSDictionary *sizes = nil;
    if (!sizes) {
        if (WLConstants.iPhone) {
            sizes = @{WLIconPresetXSmall:@(13),
                      WLIconPresetSmaller:@(14),
                      WLIconPresetSmall:@(18),
                      WLIconPresetBase:@(24),
                      WLIconPresetNormal:@(36),
                      WLIconPresetLarge:@(40),
                      WLIconPresetLarger:@(48),
                      WLIconPresetXLarge:@(72),
                      WLIconPresetLargest:@(96)};
        } else {
            sizes = @{WLIconPresetXSmall:@(13),
                      WLIconPresetSmaller:@(14),
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

+ (NSAttributedString *)iconWithName:(NSString *)name {
    return [self iconWithName:name preset:WLIconPresetBase];
}

+ (NSAttributedString *)iconWithName:(NSString *)name preset:(NSString *)preset {
    return [self iconWithName:name preset:preset color:[UIColor whiteColor]];
}

+ (NSAttributedString *)iconWithName:(NSString *)name preset:(NSString *)preset color:(UIColor *)color {
    
    static NSDictionary *icons = nil;
    if (!icons) {
        icons = @{@"circle-candy":@"a",
                  @"flash-auto":@"b",
                  @"flash-off":@"c",
                  @"flash-on":@"d",
                  @"candy":@"e",
                  @"brush":@"f",
                  @"paper-plane":@"g",
                  @"tick":@"h",
                  @"close":@"i",
                  @"cloud":@"j",
                  @"arrow-up":@"k",
                  @"checkmark":@"l",
                  @"back":@"m",
                  @"trash":@"n",
                  @"download":@"o",
                  @"ellipsis":@"p",
                  @"quote":@"q",
                  @"inbox":@"r",
                  @"warning":@"s",
                  @"photo":@"t",
                  @"camera":@"u",
                  @"simple-back":@"v",
                  @"angle-left":@"w",
                  @"angle-right":@"x",
                  @"angle-down":@"y",
                  @"angle-up":@"z",
                  @"calendar":@"A",
                  @"reply":@"B",
                  @"photos":@"C",
                  @"clock":@"D",
                  @"check":@"E",
                  @"double-check":@"F",
                  @"unselected-item":@"G",
                  @"selected-item":@"H",
				  @"edit-write":@"R",
                  @"comment-quotes":@"S",
                  @"settings":@"0",
                  @"friends":@"1",
                  @"addFriends":@"2",
                  @"pencil":@"3",
                  @"chat":@"4",
                  @"chat-bables":@"6",
                  @"restore":@"Y"};
    }
    
    NSString *code = [icons objectForKey:name];
    if (code) {
        CGFloat size = [self sizeWithPreset:preset ? : WLIconPresetBase];
        UIFont *font = [UIFont fontWithName:@"wrapliveicons" size:size];
        if (font) {
            color = color ? : [UIColor whiteColor];
            return [[NSAttributedString alloc] initWithString:code attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:color}];
        }
    } else {
        
    }
    
    return nil;
}

@end
