//
//  UIViewController+ChildPresenting.m
//  moji
//
//  Created by Sergey Maximenko on 8/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "UIViewController+Container.h"

@implementation UIViewController (Container)

- (void)addContainedViewController:(UIViewController *)controller animated:(BOOL)animated {
    [self addContainedViewController:controller toView:self.view animated:animated];
}

- (void)addContainedViewController:(UIViewController *)controller toView:(UIView*)view animated:(BOOL)animated {
    [self addChildViewController:controller];
    controller.view.frame = view.bounds;
    [view addSubview:controller.view];
    [controller didMoveToParentViewController:self];
}

- (void)removeContainedViewController:(UIViewController *)controller animated:(BOOL)animated {
    [controller removeFromContainerAnimated:animated];
}

- (void)addToContainer:(UIViewController *)container animated:(BOOL)animated {
    [container addContainedViewController:self animated:animated];
}

- (void)removeFromContainerAnimated:(BOOL)animated {
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

@end
