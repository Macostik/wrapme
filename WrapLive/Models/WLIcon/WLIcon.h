//
//  WLIcon.h
//  WrapLive
//
//  Created by Sergey Maximenko on 2/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *WLIconPresetSmaller = @"smaller";
static NSString *WLIconPresetSmall = @"small";
static NSString *WLIconPresetBase = @"base";
static NSString *WLIconPresetNormal = @"normal";
static NSString *WLIconPresetLarge = @"large";
static NSString *WLIconPresetLarger = @"larger";
static NSString *WLIconPresetXLarge = @"xlarge";
static NSString *WLIconPresetLargest = @"largest";

@interface WLIcon : NSObject

+ (NSAttributedString*)iconWithName:(NSString*)name;

+ (NSAttributedString*)iconWithName:(NSString*)name preset:(NSString*)preset;

+ (NSAttributedString*)iconWithName:(NSString*)name preset:(NSString*)preset color:(UIColor*)color;

@end

static inline NSAttributedString *WLIconCreate(NSString *name, NSString *preset, UIColor *color) {
    return [WLIcon iconWithName:name preset:preset color:color];
}
