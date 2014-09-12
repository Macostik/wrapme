//
//  UIStoryboard+Additions.h
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLEntryManager.h"

@interface UIStoryboard (WLNavigation)

+ (instancetype)mainStoryboard;

@end

static NSString* WLStoryboardSegueContributorsIdentifier = @"contributors";
static NSString* WLStoryboardSegueWrapCameraIdentifier = @"wrap_camera";
static NSString* WLStoryboardSegueCameraIdentifier = @"camera";
static NSString* WLStoryboardSegueChangeWrapIdentifier = @"changeWrap";
static NSString* WLStoryboardSegueImageIdentifier = @"image";

@interface UIStoryboardSegue (WLNavigation)

- (BOOL)isContributorsSegue;

- (BOOL)isWrapCameraSegue;

- (BOOL)isCameraSegue;

- (BOOL)isChangeWrapSegue;

- (BOOL)isImageSegue;

@end

static NSString* WLCameraNavigationControllerIdentifier = @"WLCameraNavigationController";

@interface UIViewController (WLNavigation)

+ (instancetype)instantiateWithIdentifier:(NSString*)identifier;

+ (instancetype)instantiateWithIdentifier:(NSString*)identifier confiure:(void(^)(id controller))confiure;

+ (instancetype)instantiate;

+ (instancetype)instantiate:(void(^)(id controller))confiure;

+ (instancetype)instantiateAndMakeRootViewControllerAnimated:(BOOL)animated;

+ (instancetype)instantiate:(void (^)(id controller))confiure makeRootViewControllerAnimated:(BOOL)animated;

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

- (void)present;

- (void)present:(BOOL)animated;

- (void)presentInNavigationController:(UINavigationController*)navigationController;

- (void)presentInNavigationController:(UINavigationController*)navigationController animated:(BOOL)animated;

@end

@interface WLCandy (WLNavigation) @end

@interface WLMessage (WLNavigation) @end

@interface WLWrap (WLNavigation) @end

@interface WLComment (WLNavigation) @end
