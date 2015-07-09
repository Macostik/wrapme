//
//  WLPrimaryLayoutConstraint.m
//  WrapLive
//
//  Created by Yura Granchenko on 01/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPrimaryLayoutConstraint.h"

@interface WLPrimaryLayoutConstraint ()

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *strongConstraints;
@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *weakConstraints;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *parentViews;

@end

@implementation WLPrimaryLayoutConstraint

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
    for (NSLayoutConstraint *_constraint in self.strongConstraints) {
            _constraint.priority = defaultState ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
    }
    for (NSLayoutConstraint *_constraint in self.weakConstraints) {
         _constraint.priority = defaultState ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh;
    }
    for (UIView *view in self.parentViews) {
        [view layoutIfNeeded];
    }
}

- (BOOL)defaultState {
    return [[self.strongConstraints firstObject] priority] > [[self.weakConstraints firstObject] priority];
}

@end
