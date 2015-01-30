//
//  WLIconButton.m
//  WrapLive
//
//  Created by Yura Granchenko on 27/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLIconButton.h"
#import <FAKFontAwesome.h>
#import <objc/message.h>

@implementation WLIconButton

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (instancetype)initWithFrame:(CGRect)frame iconName:(NSString *)name iconColor:(UIColor *)color iconSize:(CGFloat)size {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupWithName:name color:color size:size];
    }
    return self;
}

+ (instancetype)initWithFrame:(CGRect)frame iconName:(NSString *)name iconColor:(UIColor *)color iconSize:(CGFloat)size {
    return [[WLIconButton alloc] initWithFrame:frame iconName:name iconColor:color iconSize:size];
}

- (void)setupWithName:(NSString *)name color:(UIColor *)color size:(CGFloat)size {
    _iconName = name;
    _iconColor = color;
    _iconSize = size;
    [self setup];
}

- (void)setup {
    SEL selector = [self selectorByNameWithSize];
    if ([FAKFontAwesome respondsToSelector:selector]) {
        FAKIcon *icon = ((FAKIcon* (*)(id, SEL, CGFloat))objc_msgSend)([FAKFontAwesome class], selector, self.iconSize);
        [icon addAttribute:NSForegroundColorAttributeName value:self.iconColor];
        UIImage *image = [icon imageWithSize:CGSizeMake(self.iconSize, self.iconSize)];
        [self setImage:image forState:UIControlStateNormal];
    }
}

- (SEL)selectorByNameWithSize {
    NSMutableString *selector = [NSMutableString string];
    [selector appendFormat:@"%@IconWithSize:", self.iconName];
    return NSSelectorFromString(selector);
}

@end
