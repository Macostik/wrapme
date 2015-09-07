//
//  WLPrimaryLayoutConstraint.m
//  meWrap
//
//  Created by Yura Granchenko on 01/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLLayoutPrioritizer.h"

@interface WLLayoutPrioritizer ()

@end

@implementation WLLayoutPrioritizer

- (void)setDefaultState:(BOOL)state animated:(BOOL)animated {
    
    if (self.defaultState != state) {
        
        if (animated) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:0.25];
        }
        
        for (NSLayoutConstraint *constraint in self.defaultConstraints) {
            constraint.priority = state ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
        }
        
        for (NSLayoutConstraint *constraint in self.alternativeConstraints) {
            constraint.priority = state ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh;
        }
        
        if (self.parentViews.nonempty) {
            for (UIView *view in self.parentViews) {
                (animated || !self.asynchronous) ? [view layoutIfNeeded] : [view setNeedsLayout];
            }
        } else {
            UIView *view = [[[self.defaultConstraints firstObject] firstItem] superview];
            (animated || !self.asynchronous) ? [view layoutIfNeeded] : [view setNeedsLayout];
        }
        
        if (animated) {
            [UIView commitAnimations];
        }
    }
}

- (void)setDefaultState:(BOOL)defaultState {
    [self setDefaultState:defaultState animated:self.animated];
}

- (BOOL)defaultState {
    return [[self.defaultConstraints firstObject] priority] > [[self.alternativeConstraints firstObject] priority];
}

- (IBAction)enableDefaultState:(id)sender {
    self.defaultState = YES;
}

- (IBAction)enableAlternativeState:(id)sender {
    self.defaultState = NO;
}

- (IBAction)toggleState:(id)sender {
    self.defaultState = !self.defaultState;
}

@end
