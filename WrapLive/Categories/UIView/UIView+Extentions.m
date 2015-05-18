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
