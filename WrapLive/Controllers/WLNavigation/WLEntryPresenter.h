//
//  WLEntryPresenter.h
//  wrapLive
//
//  Created by Sergey Maximenko on 4/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLEntryPresenter : NSObject

+ (void)presentEntry:(WLEntry*)entry animated:(BOOL)animated;

+ (void)presentEntry:(WLEntry*)entry inNavigationController:(UINavigationController*)navigationController animated:(BOOL)animated;

+ (void)presentEntryRequestingAuthorization:(WLEntry*)entry animated:(BOOL)animated;

+ (void)presentEntryRequestingAuthorization:(WLEntry*)entry inNavigationController:(UINavigationController*)navigationController animated:(BOOL)animated;

@end

@interface UIViewController (WLEntryPresenter)

- (void)requestAuthorizationForPresentingEntry:(WLEntry*)entry completion:(WLBooleanBlock)completion;

@end

@interface WLEntry (WLNavigation)

- (UIViewController *)viewController;

- (UIViewController *)viewControllerWithNavigationController:(UINavigationController*)navigationController;

- (BOOL)isValidViewController:(UIViewController*)controller;

- (void)configureViewController:(UIViewController*)controller fromContainingEntry:(WLEntry*)containingEntry;

@end

@interface WLCandy (WLNavigation) @end

@interface WLMessage (WLNavigation) @end

@interface WLWrap (WLNavigation) @end

@interface WLComment (WLNavigation) @end