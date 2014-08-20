//
//  UIViewController+PGNavigationBack.h
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 6/14/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Additions)

- (void)pushViewController:(UIViewController*)controller animated:(BOOL)animated;
- (BOOL)isOnTopOfNagvigation;
- (void)pushViewControllerNextToCurrent:(UIViewController*)controller animated:(BOOL)animated;
- (void)pushViewControllerNextToRootViewController:(UIViewController*)controller animated:(BOOL)animated;
- (void)pushViewController:(UIViewController*)controller nextToViewController:(UIViewController*)nextToController animated:(BOOL)animated;

- (IBAction)back:(UIButton *)sender;

@end
