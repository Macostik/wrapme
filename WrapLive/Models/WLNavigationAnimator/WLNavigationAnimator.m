//
//  WLNavigationAnimator.m
//  WrapLive
//
//  Created by Sergey Maximenko on 12/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNavigationAnimator.h"
#import "UIView+Shorthand.h"

@implementation WLNavigationAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.5f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    // Grab the from and to view controllers from the context
    __block UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    __block UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // Set our ending frame. We'll modify this later if we have to
    
    CGAffineTransform fromStartTransform;
    CGAffineTransform toStartTransform;
    CGAffineTransform fromEndTransform;
    CGAffineTransform toEndTransform;
    
    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
        toViewController.view.frame = fromViewController.view.frame;
        
        [transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:toViewController.view];
        if (self.modal) {
            toStartTransform = CGAffineTransformMakeTranslation(0, toViewController.view.height);
            fromStartTransform = CGAffineTransformIdentity;
            toEndTransform = CGAffineTransformIdentity;
            fromEndTransform = CGAffineTransformMakeScale(0.8, 0.8);
        } else {
            toStartTransform = CGAffineTransformMakeTranslation(toViewController.view.width, 0);
            fromStartTransform = CGAffineTransformIdentity;
            toEndTransform = CGAffineTransformIdentity;
            fromEndTransform = CGAffineTransformMakeScale(0.8, 0.8);
        }
    } else {
        toViewController.view.userInteractionEnabled = YES;
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView addSubview:fromViewController.view];
        if (self.modal) {
            toStartTransform = CGAffineTransformMakeScale(0.8, 0.8);
            fromStartTransform = CGAffineTransformIdentity;
            toEndTransform = CGAffineTransformIdentity;
            fromEndTransform = CGAffineTransformMakeTranslation(0, fromViewController.view.height);
        } else {
            toStartTransform = CGAffineTransformMakeScale(0.8, 0.8);
            fromStartTransform = CGAffineTransformIdentity;
            toEndTransform = CGAffineTransformIdentity;
            fromEndTransform = CGAffineTransformMakeTranslation(fromViewController.view.width, 0);
        }
    }
    
    toViewController.view.transform = toStartTransform;
    fromViewController.view.transform = fromStartTransform;
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.3 options:UIViewAnimationOptionCurveEaseIn animations:^{
        fromViewController.view.transform = fromEndTransform;
        toViewController.view.transform = toEndTransform;
    } completion:^(BOOL finished) {
        fromViewController.view.transform = CGAffineTransformIdentity;
        toViewController.view.transform = CGAffineTransformIdentity;
        [transitionContext completeTransition:YES];
    }];
}

@end
