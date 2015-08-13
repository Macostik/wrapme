//
//  UIView+QuartzCoreHelper.m
//  Moji
//
//  Created by Sergey Maximenko on 8/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "UIView+QuartzCoreHelper.h"

@implementation UIView (QuartzCoreHelper)

- (UIColor *)borderColor {
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setBorderColor:(UIColor *)borderColor {
    self.layer.borderColor = borderColor.CGColor;
}

- (CGFloat)cornerRadius {
    return self.layer.cornerRadius;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)borderWidth {
    return  self.layer.borderWidth;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.layer.borderWidth = borderWidth;
}

@end