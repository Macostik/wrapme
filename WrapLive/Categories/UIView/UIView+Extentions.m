//
//  UIView+Extentions.m
//  
//  Created by Yuriy Granchenko on 28.05.14.
//  Copyright (c) 2014 Roman. All rights reserved.
//
#import "UIView+Extentions.h"
#import "NSError+WLAPIManager.h"
#import "NSObject+AssociatedObjects.h"

@implementation UIView (Extentions)

- (UIView *)parentView {
	return [self associatedObjectForKey:"parentView"];
}

- (void)setParentView:(UIView *)parentView{
	[self setAssociatedObject:parentView forKey:"parentView"];
}

- (void)logSubviewsHierarchy {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#ifdef DEBUG
	WLLog(@"SubviewsHierarchy \n\n", [self performSelector:@selector(recursiveDescription)], nil);
#endif
}

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

- (void)setHighHorizontalContentCompressionResistance:(BOOL)flag {
    [self setHorizontalContentCompressionResistancePriority:flag ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow];
}

- (BOOL)highHorizontalContentCompressionResistance {
    return [self contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisHorizontal] == UILayoutPriorityDefaultHigh;
}

- (void)setHighVerticalContentCompressionResistance:(BOOL)flag {
    [self setVerticalContentCompressionResistancePriority:flag ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow];
}

- (BOOL)highVerticalContentCompressionResistance {
    return [self contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisVertical] == UILayoutPriorityDefaultHigh;
}

- (void)setLowHorizontalContentCompressionResistance:(BOOL)flag {
    [self setHorizontalContentCompressionResistancePriority:flag ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh];
}

- (BOOL)lowHorizontalContentCompressionResistance {
    return [self contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisHorizontal] == UILayoutPriorityDefaultLow;
}

- (void)setLowVerticalContentCompressionResistance:(BOOL)flag {
    [self setVerticalContentCompressionResistancePriority:flag ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh];
}

- (BOOL)lowVerticalContentCompressionResistance {
    return [self contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisVertical] == UILayoutPriorityDefaultLow;
}

- (void)setHighHorizontalContentHugging:(BOOL)flag {
    [self setHorizontalContentCompressionResistancePriority:flag ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow];
}

- (BOOL)highHorizontalContentHugging {
    return [self contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal] == UILayoutPriorityDefaultHigh;
}

- (void)setHighVerticalContentHugging:(BOOL)flag {
    [self setVerticalContentHuggingPriority:flag ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow];
}

- (BOOL)highVerticalContentHugging {
    return [self contentHuggingPriorityForAxis:UILayoutConstraintAxisVertical] == UILayoutPriorityDefaultHigh;
}

- (void)setLowHorizontalContentHugging:(BOOL)flag {
    [self setHorizontalContentHuggingPriority:flag ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh];
}

- (BOOL)lowHorizontalContentHugging {
    return [self contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal] == UILayoutPriorityDefaultLow;
}

- (void)setLowVerticalContentHugging:(BOOL)flag {
    [self setVerticalContentHuggingPriority:flag ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh];
}

- (BOOL)lowVerticalContentHugging {
    return [self contentHuggingPriorityForAxis:UILayoutConstraintAxisVertical] == UILayoutPriorityDefaultLow;
}

- (void)setHorizontalContentCompressionResistancePriority:(CGFloat)priority {
    [self setContentCompressionResistancePriority:priority forAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setVerticalContentCompressionResistancePriority:(CGFloat)priority {
    [self setContentCompressionResistancePriority:priority forAxis:UILayoutConstraintAxisVertical];
}

- (void)setHorizontalContentHuggingPriority:(CGFloat)priority {
    [self setContentHuggingPriority:priority forAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setVerticalContentHuggingPriority:(CGFloat)priority {
    [self setContentHuggingPriority:priority forAxis:UILayoutConstraintAxisVertical];
}

- (id)findFirstResponder {
    if (self.isFirstResponder) {
        return self;
    }
    for (UIView *subView in self.subviews) {
        UIView *firstResponder = [subView findFirstResponder];
        if (firstResponder) {
            return firstResponder;
        }
    }
    return nil;
}

@end
