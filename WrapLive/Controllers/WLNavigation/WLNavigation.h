//
//  UIStoryboard+Additions.h
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLEntryManager.h"

static NSString *WLMainStoryboard = @"Main";
static NSString *WLSignUpStoryboard = @"SignUp";
static NSString *WLCameraStoryboard = @"Camera";

@interface UIStoryboard (WLNavigation)

+ (UIStoryboard *)storyboardNamed:(NSString *)name;

+ (void)setStoryboard:(UIStoryboard*)storyboard named:(NSString *)name;

@end

@interface UIViewController (WLNavigation)

+ (instancetype)instantiateWithIdentifier:(NSString*)identifier storyboard:(UIStoryboard*)storyboard;

+ (instancetype)instantiate:(UIStoryboard*)storyboard;

@end

@interface UINavigationController (WLNavigation)

+ (instancetype)mainNavigationController;

+ (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

+ (UIViewController *)popViewControllerAnimated:(BOOL)animated;

+ (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;

+ (NSArray *)popToRootViewControllerAnimated:(BOOL)animated;

+ (id)topViewController;

+ (void)setViewControllers:(NSArray *)viewControllers;

+ (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated;

- (void)pushUniqueClassViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end

@interface UIWindow (WLNavigation)

+ (instancetype)mainWindow;

+ (void)setMainWindow:(UIWindow*)window;

@end

@interface WLEntry (WLNavigation)

- (UIViewController*)viewController;

- (BOOL)isValidViewController:(UIViewController*)controller;

- (void)present;

- (void)present:(BOOL)animated;

- (void)presentInNavigationController:(UINavigationController*)navigationController;

- (void)presentInNavigationController:(UINavigationController*)navigationController animated:(BOOL)animated;

- (void)presentAndDissmisViewController;

@end

@interface WLCandy (WLNavigation) @end

@interface WLMessage (WLNavigation) @end

@interface WLWrap (WLNavigation) @end

@interface WLComment (WLNavigation) @end
