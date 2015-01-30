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

@property (assign, nonatomic) IBInspectable CGFloat iconSize;

+ (instancetype)initWithFrame:(CGRect)frame iconName:(NSString *)name iconColor:(UIColor *)color iconSize:(CGFloat)size;

- (instancetype)initWithFrame:(CGRect)frame iconName:(NSString *)name iconColor:(UIColor *)color iconSize:(CGFloat)size;

- (void)setupWithName:(NSString *)name color:(UIColor *)color size:(CGFloat)size;

@end
