//
//  UIView+LayoutHelper.m
//  wrapLive
//
//  Created by Sergey Maximenko on 7/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "UIView+LayoutHelper.h"

@implementation UIView (LayoutHelper)

- (void)makeResizibleSubview:(UIView *)view {
    [self addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
}

- (NSLayoutConstraint *)constraintToItem:(id)item equal:(NSLayoutAttribute)attribute {
    return [self constraintForAttrbute:attribute toItem:item equalToAttribute:attribute];
}

- (NSLayoutConstraint *)constraintForAttrbute:(NSLayoutAttribute)attribute1 toItem:(id)item equalToAttribute:(NSLayoutAttribute)attribute2 {
    return [NSLayoutConstraint constraintWithItem:self attribute:attribute1 relatedBy:NSLayoutRelationEqual toItem:item attribute:attribute2 multiplier:1 constant:0];
}

- (void)setHorizontallyResistible:(BOOL)horizontallyResistible {
    self.horizontalContentCompressionResistancePriority = horizontallyResistible ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
}

- (BOOL)horizontallyResistible {
    return self.horizontalContentCompressionResistancePriority == UILayoutPriorityDefaultHigh;
}

- (void)setVerticallyResistible:(BOOL)verticallyResistible {
    self.verticalContentCompressionResistancePriority = verticallyResistible ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
}

- (BOOL)verticallyResistible {
    return self.verticalContentCompressionResistancePriority == UILayoutPriorityDefaultHigh;
}

- (void)setHorizontallyHuggable:(BOOL)horizontallyHuggable {
    self.horizontalContentHuggingPriority = horizontallyHuggable ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
}

- (BOOL)horizontallyHuggable {
    return self.horizontalContentHuggingPriority == UILayoutPriorityDefaultHigh;
}

- (void)setVerticallyHuggable:(BOOL)verticallyHuggable {
    self.verticalContentHuggingPriority = verticallyHuggable ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
}

- (BOOL)verticallyHuggable {
    return self.verticalContentHuggingPriority == UILayoutPriorityDefaultHigh;
}

- (void)setHorizontalContentCompressionResistancePriority:(CGFloat)priority {
    [self setContentCompressionResistancePriority:priority forAxis:UILayoutConstraintAxisHorizontal];
}

- (CGFloat)horizontalContentCompressionResistancePriority {
    return [self contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setVerticalContentCompressionResistancePriority:(CGFloat)priority {
    [self setContentCompressionResistancePriority:priority forAxis:UILayoutConstraintAxisVertical];
}

- (CGFloat)verticalContentCompressionResistancePriority {
    return [self contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisVertical];
}

- (void)setHorizontalContentHuggingPriority:(CGFloat)priority {
    [self setContentHuggingPriority:priority forAxis:UILayoutConstraintAxisHorizontal];
}

- (CGFloat)horizontalContentHuggingPriority {
    return [self contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setVerticalContentHuggingPriority:(CGFloat)priority {
    [self setContentHuggingPriority:priority forAxis:UILayoutConstraintAxisVertical];
}

- (CGFloat)verticalContentHuggingPriority {
    return [self contentHuggingPriorityForAxis:UILayoutConstraintAxisVertical];
}

@end
