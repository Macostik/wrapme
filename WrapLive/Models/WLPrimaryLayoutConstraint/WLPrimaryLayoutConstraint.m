//
//  WLPrimaryLayoutConstraint.m
//  WrapLive
//
//  Created by Yura Granchenko on 01/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPrimaryLayoutConstraint.h"

@interface WLPrimaryLayoutConstraint ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *strongConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *weakConstraint;
@property (weak, nonatomic) IBOutlet UIView *parentView;

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
    if (self.strongConstraint.priority != self.weakConstraint.priority) {
        self.strongConstraint.priority = defaultState ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
        self.weakConstraint.priority = defaultState ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh;
        if (self.parentView != nil) {
            [self.parentView layoutIfNeeded];
        } else {
            [self.strongConstraint.firstItem layoutIfNeeded];
        }
    }
}

- (BOOL)defaultState {
    return self.strongConstraint.priority > self.weakConstraint.priority;
}

@end
