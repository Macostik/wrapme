//
//  WLIcon.h
//  WrapLive
//
//  Created by Sergey Maximenko on 2/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FontAwesomeKit.h"

static NSString *WLIconPresetSmaller = @"smaller";
static NSString *WLIconPresetSmall = @"small";
static NSString *WLIconPresetBase = @"base";
static NSString *WLIconPresetNormal = @"normal";
static NSString *WLIconPresetLarge = @"large";
static NSString *WLIconPresetLarger = @"larger";
static NSString *WLIconPresetXLarge = @"xlarge";
static NSString *WLIconPresetLargest = @"largest";

@interface WLIcon : FAKIcon

+ (FAKIcon*)iconWithName:(NSString*)name;

+ (FAKIcon*)iconWithName:(NSString*)name preset:(NSString*)preset;

+ (FAKIcon*)iconWithName:(NSString*)name preset:(NSString*)preset color:(UIColor*)color;

@end
