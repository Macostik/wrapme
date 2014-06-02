//
//  UIStoryboard+Additions.h
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIStoryboard (Additions)

+ (instancetype)mainStoryboard;

@end

static NSString* WLStoryboardSegueContributorsIdentifier = @"contributors";
static NSString* WLStoryboardSegueCameraIdentifier = @"camera";
static NSString* WLStoryboardSegueChangeWrapIdentifier = @"changeWrap";
static NSString* WLStoryboardSegueImageIdentifier = @"image";

@interface UIStoryboardSegue (Additions)

- (BOOL)isContributorsSegue;

- (BOOL)isCameraSegue;

- (BOOL)isChangeWrapSegue;

- (BOOL)isImageSegue;

@end

static NSString* WLCameraNavigationControllerIdentifier = @"WLCameraNavigationController";

@interface UIViewController (StoryboardAdditions)

+ (instancetype)instantiateWithIdentifier:(NSString*)identifier;

+ (instancetype)instantiateWithIdentifier:(NSString*)identifier confiure:(void(^)(id controller))confiure;

+ (instancetype)instantiate;

+ (instancetype)instantiate:(void(^)(id controller))confiure;

+ (instancetype)instantiateAndMakeRootViewControllerAnimated:(BOOL)animated;

+ (instancetype)instantiate:(void (^)(id controller))confiure makeRootViewControllerAnimated:(BOOL)animated;

@end

@interface UINavigationController (StoryboardAdditions)

+ (instancetype)mainNavigationController;

+ (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

+ (UIViewController *)popViewControllerAnimated:(BOOL)animated;

+ (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;

+ (NSArray *)popToRootViewControllerAnimated:(BOOL)animated;

+ (id)topViewController;

+ (void)setViewControllers:(NSArray *)viewControllers;

+ (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated;

@end

@interface UIWindow (StoryboardAdditions)

+ (instancetype)mainWindow;

@end
