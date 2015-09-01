//
//  UIStoryboard+Additions.h
//  moji
//
//  Created by Ravenpod on 27.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *WLMainStoryboard = @"Main";
static NSString *WLSignUpStoryboard = @"SignUp";
static NSString *WLCameraStoryboard = @"Camera";
static NSString *WLIntroductionStoryboard = @"Introduction";

@interface UIStoryboard (WLNavigation)

+ (UIStoryboard *)storyboardNamed:(NSString *)name;

+ (void)setStoryboard:(UIStoryboard*)storyboard named:(NSString *)name;

- (void)present:(BOOL)animated;

@end

@interface UIViewController (WLNavigation)

@property (readonly, nonatomic) BOOL isTopViewController;

+ (instancetype)instantiateWithIdentifier:(NSString*)identifier storyboard:(UIStoryboard*)storyboard;

+ (instancetype)instantiate:(UIStoryboard*)storyboard;

- (void)requestAuthorizationForPresentingEntry:(WLEntry*)entry completion:(WLBooleanBlock)completion;

- (void)pushViewController:(UIViewController*)controller animated:(BOOL)animated;

- (void)pushViewControllerNextToCurrent:(UIViewController*)controller animated:(BOOL)animated;

- (void)pushViewControllerNextToRootViewController:(UIViewController*)controller animated:(BOOL)animated;

- (void)pushViewController:(UIViewController*)controller nextToViewController:(UIViewController*)nextToController animated:(BOOL)animated;

- (IBAction)back:(UIButton *)sender;

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
