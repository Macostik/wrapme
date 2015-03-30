//
//  WLNavigationAnimator.m
//  WrapLive
//
//  Created by Sergey Maximenko on 12/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNavigationAnimator.h"
#import "UIView+Shorthand.h"
#import "NSObject+AssociatedObjects.h"

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
    fromViewController.view.userInteractionEnabled = toViewController.view.userInteractionEnabled = NO;
    if (self.presenting) {
        
        toViewController.view.frame = fromViewController.view.frame;
        [transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:toViewController.view];
        if (toViewController.animatorPresentationType == WLNavigationAnimatorPresentationTypeModal) {
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
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView addSubview:fromViewController.view];
        if (fromViewController.animatorPresentationType == WLNavigationAnimatorPresentationTypeModal) {
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
        fromViewController.view.userInteractionEnabled = toViewController.view.userInteractionEnabled = YES;
    }];
}

@end

@implementation UIViewController (WLNavigationAnimator)

- (void)setAnimatorPresentationType:(WLNavigationAnimatorPresentationType)animatorPresentationType {
    [self setAssociatedObject:@(animatorPresentationType) forKey:"animatorPresentationType"];
}

- (WLNavigationAnimatorPresentationType)animatorPresentationType {
    return [[self associatedObjectForKey:"animatorPresentationType"] integerValue];
}

@end
