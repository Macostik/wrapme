//
//  WLEntryPresenter.h
//  moji
//
//  Created by Ravenpod on 4/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLEntryManager.h"

@interface WLEntryPresenter : NSObject

+ (void)presentEntry:(WLEntry*)entry animated:(BOOL)animated;

+ (void)presentEntry:(WLEntry*)entry inNavigationController:(UINavigationController*)navigationController animated:(BOOL)animated;

+ (void)presentEntryRequestingAuthorization:(WLEntry*)entry animated:(BOOL)animated;

+ (void)presentEntryRequestingAuthorization:(WLEntry*)entry inNavigationController:(UINavigationController*)navigationController animated:(BOOL)animated;

@end

@interface UIViewController (WLEntryPresenter)

- (void)requestAuthorizationForPresentingEntry:(WLEntry*)entry completion:(WLBooleanBlock)completion;

@end

@interface WLEntry (WLEntryPresenter)

- (UIViewController *)viewController;

- (UIViewController *)viewControllerWithNavigationController:(UINavigationController*)navigationController;

- (UIViewController *)recursiveViewControllerWithNavigationController:(UINavigationController*)navigationController;

- (BOOL)isValidViewController:(UIViewController*)controller;

- (void)configureViewController:(UIViewController*)controller fromContainer:(WLEntry*)container;

@end

@interface WLCandy (WLEntryPresenter) @end

@interface WLMessage (WLEntryPresenter) @end

@interface WLWrap (WLEntryPresenter) @end

@interface WLComment (WLEntryPresenter) @end
