//
//  UIViewController+ChildPresenting.h
//  moji
//
//  Created by Sergey Maximenko on 8/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Container)

- (void)addContainedViewController:(UIViewController *)controller animated:(BOOL)animated;

- (void)addContainedViewController:(UIViewController *)controller toView:(UIView*)view animated:(BOOL)animated;

- (void)removeContainedViewController:(UIViewController *)controller animated:(BOOL)animated;

- (void)addToContainer:(UIViewController *)container animated:(BOOL)animated;

- (void)removeFromContainerAnimated:(BOOL)animated;

@end
