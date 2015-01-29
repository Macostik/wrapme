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
    NSAssert(self.iconName, nil);
    [selector appendFormat:@"%@IconWithSize:", self.iconName];
    return NSSelectorFromString(selector);
}

@end
