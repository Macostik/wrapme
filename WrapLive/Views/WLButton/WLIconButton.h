//
//  WLIconButton.h
//  WrapLive
//
//  Created by Yura Granchenko on 27/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLButton.h"

@interface WLIconButton : WLButton

@property (strong, nonatomic) IBInspectable NSString *iconName;

@property (strong, nonatomic) IBInspectable UIColor *iconColor;

@property (strong, nonatomic) IBInspectable NSString *iconPreset;

@property (nonatomic) IBInspectable BOOL circled;

+ (instancetype)iconButtonWithFrame:(CGRect)frame iconName:(NSString *)name iconColor:(UIColor *)color preset:(NSString*)preset;

- (instancetype)initWithFrame:(CGRect)frame iconName:(NSString *)name iconColor:(UIColor *)color preset:(NSString*)preset;

- (void)setupWithName:(NSString *)name color:(UIColor *)color preset:(NSString*)preset;

@end
