//
//  WLPrimaryLayoutConstraint.m
//  WrapLive
//
//  Created by Yura Granchenko on 01/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLLayoutPrioritizer.h"

@interface WLLayoutPrioritizer ()

@end

@implementation WLLayoutPrioritizer

- (void)setDefaultState:(BOOL)state animated:(BOOL)animated {
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.25];
        self.defaultState = state;
        [UIView commitAnimations];
    } else {
        self.defaultState = state;
    }
}

- (void)setDefaultState:(BOOL)defaultState {
    if (self.defaultState != defaultState) {
        for (NSLayoutConstraint *constraint in self.defaultConstraints) {
            constraint.priority = defaultState ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
        }
        for (NSLayoutConstraint *constraint in self.alternativeConstraints) {
            constraint.priority = defaultState ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh;
        }
        if (self.parentViews.nonempty) {
            for (UIView *view in self.parentViews) {
                [view layoutIfNeeded];
            }
        } else {
            [[[[self.defaultConstraints firstObject] firstItem] superview] layoutIfNeeded];
        }
    }
}

- (BOOL)defaultState {
    return [[self.defaultConstraints firstObject] priority] > [[self.alternativeConstraints firstObject] priority];
}

@end
