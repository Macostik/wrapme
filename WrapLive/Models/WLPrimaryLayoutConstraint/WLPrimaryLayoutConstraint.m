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

- (void)performSwitchConstraints {
    [self performSwitchConstraintsAnimated:YES];
}

- (void)performSwitchConstraintsAnimated:(BOOL)animated {
    [self performSwitchConstraintsAnimated:(BOOL)animated duration:1.0];
}

- (void)performSwitchConstraintsAnimated:(BOOL)animated duration:(CGFloat)duration {
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:duration];
        [self exchangePriorityConstraints];
        [UIView commitAnimations];
    } else {
        [self exchangePriorityConstraints];
    }
}

- (void)exchangePriorityConstraints {
    if (self.strongConstraint.priority != self.weakConstraint.priority) {
        UILayoutPriority firstPriority = self.strongConstraint.priority;
        UILayoutPriority secondPriority = self.weakConstraint.priority;
        self.strongConstraint.priority = secondPriority;
        self.weakConstraint.priority = firstPriority;
        if (self.parentView != nil) {
            [self.parentView layoutIfNeeded];
        } else {
            [self.strongConstraint.firstItem layoutIfNeeded];
        }
    }
}

- (BOOL)isDefaultPriotiry {
    return self.strongConstraint.priority > self.weakConstraint.priority;
}

@end
