//
//  WLIconButton.m
//  WrapLive
//
//  Created by Yura Granchenko on 27/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLIconButton.h"
#import <FAKFontAwesome.h>

@implementation WLIconButton

- (void)awakeFromNib {
    [super awakeFromNib];
    
    SEL selector = [self selectorByNameWithSize];
    if ([FAKFontAwesome respondsToSelector:selector]) {
        CGFloat first = self.size;
        void *value = nil;
        
        NSMethodSignature *methSig = [FAKFontAwesome methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methSig];
        
        [invocation setSelector:selector];
        [invocation setTarget:[FAKFontAwesome class]];
        [invocation setArgument:&first atIndex:2];
        [invocation invoke];
        [invocation getReturnValue:&value];
        
        FAKIcon *icon = (__bridge FAKIcon *)(value);
        [icon addAttribute:NSForegroundColorAttributeName value:self.color];
        UIImage *image = [icon imageWithSize:CGSizeMake(self.size, self.size)];
        [self setImage:image forState:UIControlStateNormal];
    }
}

- (SEL)selectorByNameWithSize {
    NSMutableString *selector = [NSMutableString string];
    NSAssert(self.name, nil);
    [selector appendFormat:@"%@IconWithSize:", self.name];
    return NSSelectorFromString(selector);
}

@end
