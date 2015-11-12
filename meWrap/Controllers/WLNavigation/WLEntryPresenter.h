//
//  WLEntryPresenter.h
//  meWrap
//
//  Created by Ravenpod on 4/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLEntryPresenter : NSObject

+ (void)presentEntry:(Entry *)entry animated:(BOOL)animated;

+ (void)presentEntry:(Entry *)entry inNavigationController:(UINavigationController*)navigationController animated:(BOOL)animated;

+ (void)presentEntryRequestingAuthorization:(Entry *)entry animated:(BOOL)animated;

+ (void)presentEntryRequestingAuthorization:(Entry *)entry inNavigationController:(UINavigationController*)navigationController animated:(BOOL)animated;

@end

@interface UIViewController (WLEntryPresenter)

- (void)requestAuthorizationForPresentingEntry:(Entry *)entry completion:(WLBooleanBlock)completion;

@end

@interface Entry (WLEntryPresenter)

- (UIViewController *)viewController;

- (UIViewController *)viewControllerWithNavigationController:(UINavigationController*)navigationController;

- (UIViewController *)recursiveViewControllerWithNavigationController:(UINavigationController*)navigationController;

- (BOOL)isValidViewController:(UIViewController*)controller;

- (void)configureViewController:(UIViewController*)controller fromContainer:(Entry *)container;

@end

@interface Candy (WLEntryPresenter) @end

@interface Message (WLEntryPresenter) @end

@interface Wrap (WLEntryPresenter) @end

@interface Comment (WLEntryPresenter) @end
