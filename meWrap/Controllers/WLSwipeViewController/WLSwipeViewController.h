//
//  WLSwipeViewController.h
//  meWrap
//
//  Created by Ravenpod on 5/7/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

typedef NS_ENUM(NSInteger, WLSwipeViewControllerDirection) {
    WLSwipeViewControllerDirectionForward,
    WLSwipeViewControllerDirectionReverse
};

@interface WLSwipeViewController : WLBaseViewController

@property (weak, nonatomic) UIViewController *viewController;

@property (weak, nonatomic, readonly) UIScrollView* scrollView;

- (UIViewController*)viewControllerAfterViewController:(UIViewController*)viewController;

- (UIViewController*)viewControllerBeforeViewController:(UIViewController*)viewController;

- (void)setViewController:(UIViewController*)viewController direction:(WLSwipeViewControllerDirection)direction animated:(BOOL)animated;

- (void)setViewController:(UIViewController*)viewController direction:(WLSwipeViewControllerDirection)direction animated:(BOOL)animated completion:(WLBlock)completion;

- (void)didChangeViewController:(UIViewController*)viewController;

- (void)didChangeOffsetForViewController:(UIViewController*)viewController offset:(CGFloat)offset;

@end
