//
//  UIStoryboard+Additions.m
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLNavigation.h"
#import "WLWrapViewController.h"
#import "WLCandyViewController.h"
#import "WLChatViewController.h"
#import "NSArray+Additions.h"

@implementation UIStoryboard (WLNavigation)

+ (instancetype)mainStoryboard {
	UIWindow* window = [[[UIApplication sharedApplication] windows] firstObject];
	return window.rootViewController.storyboard;
}

@end

@implementation UIStoryboardSegue (WLNavigation)

- (BOOL)isContributorsSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueContributorsIdentifier];
}

- (BOOL)isWrapCameraSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueWrapCameraIdentifier];
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

@implementation UIViewController (WLNavigation)

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

@implementation UINavigationController (WLNavigation)

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

- (void)pushUniqueClassViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSMutableArray* controllers = [NSMutableArray array];
    for (UIViewController* _controller in self.viewControllers) {
        if ([_controller isKindOfClass:[viewController class]]) {
            [controllers addObject:viewController];
            break;
        } else {
            [controllers addObject:_controller];
        }
    }
    if (![controllers containsObject:viewController]) [controllers addObject:viewController];
    [self setViewControllers:controllers animated:animated];
}

@end

@implementation UIWindow (WLNavigation)

static UIWindow* mainWindow = nil;

+ (instancetype)mainWindow {
    if (mainWindow == nil) mainWindow = [[[UIApplication sharedApplication] windows] firstObject];
	return mainWindow;
}

+ (void)setMainWindow:(UIWindow *)window {
    mainWindow = window;
}

@end

@implementation WLEntry (WLNavigation)

- (UIViewController *)viewController {
    return nil;
}

- (void)present {
    [self present:YES];
}

- (void)present:(BOOL)animated {
    [self presentInNavigationController:[UINavigationController mainNavigationController] animated:animated];
}

- (void)presentInNavigationController:(UINavigationController*)navigationController {
    [self presentInNavigationController:navigationController animated:YES];
}

- (void)presentInNavigationController:(UINavigationController*)navigationController animated:(BOOL)animated {
    UIViewController* entryViewController = [self viewController];
    if (entryViewController) {
        [navigationController pushUniqueClassViewController:entryViewController animated:animated];
    }
}

@end

@implementation WLCandy (WLNavigation)

- (UIViewController *)viewController {
    __weak typeof(self)weakSelf = self;
    return [WLCandyViewController instantiate:^(WLCandyViewController *controller) {
        controller.candy = weakSelf;
    }];
}

@end

@implementation WLMessage (WLNavigation)

- (UIViewController *)viewController {
    __weak typeof(self)weakSelf = self;
    return [WLChatViewController instantiate:^(WLChatViewController *controller) {
        controller.wrap = weakSelf.wrap;
    }];
}

@end

@implementation WLWrap (WLNavigation)

- (UIViewController *)viewController {
    __weak typeof(self)weakSelf = self;
    return [WLWrapViewController instantiate:^(WLWrapViewController *controller) {
        controller.wrap = weakSelf;
    }];
}

@end

@implementation WLComment (WLNavigation)

- (UIViewController *)viewController {
    return [self.candy viewController];
}

@end
