//
//  UIStoryboard+Additions.m
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLNavigation.h"
#import "WLSupportFunctions.h"

@implementation UIStoryboard (Additions)

+ (instancetype)mainStoryboard {
	UIWindow* window = [[[UIApplication sharedApplication] windows] firstObject];
	return window.rootViewController.storyboard;
}

@end

@implementation UIStoryboardSegue (Additions)

- (BOOL)isContributorsSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueContributorsIdentifier];
}

- (BOOL)isCameraSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueCameraIdentifier];
}

- (BOOL)isChangeWrapSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueChangeWrapIdentifier];
}

- (BOOL)isImageSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueImageIdentifier];
}

@end

@implementation UIViewController (StoryboardAdditions)

+ (instancetype)instantiateWithIdentifier:(NSString*)identifier confiure:(void (^)(id controller))confiure {
	id controller = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:identifier];
	if ([controller isKindOfClass:self]) {
		if (confiure) {
			confiure(controller);
		}
		return controller;
	}
	return nil;
}

+ (instancetype)instantiateWithIdentifier:(NSString *)identifier {
	return [self instantiateWithIdentifier:identifier confiure:nil];
}

+ (instancetype)instantiate {
	return [self instantiate:nil];
}

+ (instancetype)instantiate:(void (^)(id controller))confiure {
	return [self instantiateWithIdentifier:NSStringFromClass(self) confiure:confiure];
}

+ (instancetype)instantiateAndMakeRootViewControllerAnimated:(BOOL)animated {
	return [self instantiate:nil makeRootViewControllerAnimated:animated];
}

+ (instancetype)instantiate:(void (^)(id controller))confiure makeRootViewControllerAnimated:(BOOL)animated {
	id controller = [self instantiate:confiure];
	if (controller) {
		[UINavigationController setViewControllers:@[controller] animated:animated];
	}
	return controller;
}

@end

@implementation UINavigationController (StoryboardAdditions)

+ (instancetype)mainNavigationController {
	UINavigationController *mainNavigationController = (id)[[UIWindow mainWindow] rootViewController];
	if ([mainNavigationController isKindOfClass:[UINavigationController class]]) {
		return mainNavigationController;
	}
	return nil;
}

+ (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
	[[self mainNavigationController] pushViewController:viewController animated:animated];
}

+ (UIViewController *)popViewControllerAnimated:(BOOL)animated {
	return [[self mainNavigationController] popViewControllerAnimated:animated];
}

+ (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
	return [[self mainNavigationController] popToViewController:viewController animated:animated];
}

+ (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
	return [[self mainNavigationController] popToRootViewControllerAnimated:animated];
}

+ (id)topViewController {
	return [[self mainNavigationController] topViewController];
}

+ (void)setViewControllers:(NSArray *)viewControllers {
	[[self mainNavigationController] setViewControllers:viewControllers];
}

+ (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
	[[self mainNavigationController] setViewControllers:viewControllers animated:animated];
}

@end

@implementation UIWindow (StoryboardAdditions)

static UIWindow* mainWindow = nil;

+ (instancetype)mainWindow {
    if (mainWindow == nil) {
        mainWindow = [[[UIApplication sharedApplication] windows] firstObject];
    }
	return mainWindow;
}

+ (void)setMainWindow:(UIWindow *)window {
    mainWindow = window;
}

@end
