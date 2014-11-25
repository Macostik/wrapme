//
//  WLTextField.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTextField.h"

@implementation WLTextField

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    UIBezierPath* path = [UIBezierPath bezierPath];
    CGFloat lineWidth = 1.0f/[UIScreen mainScreen].scale;
    path.lineWidth = lineWidth;
    CGFloat y = self.bounds.size.height - path.lineWidth/2.0f;
    [path moveToPoint:CGPointMake(0, y)];
    [path addLineToPoint:CGPointMake(self.bounds.size.width, y)];
    UIColor *placeholderColor = [self.attributedPlaceholder attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL];
    [placeholderColor setStroke];
    [path stroke];
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self sendActionsForControlEvents:UIControlEventEditingChanged];
}

@end
