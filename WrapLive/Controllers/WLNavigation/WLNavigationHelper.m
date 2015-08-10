//
//  UIStoryboard+Additions.m
//  moji
//
//  Created by Ravenpod on 27.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNavigationHelper.h"

@implementation UIStoryboard (WLNavigation)

static NSMapTable *storyboards = nil;

+ (UIStoryboard *)storyboardNamed:(NSString *)name {
    if (!storyboards) {
        storyboards = [NSMapTable strongToWeakObjectsMapTable];
    }
    UIStoryboard* storyboard = [storyboards objectForKey:name];
    if (!storyboard) {
        storyboard = [UIStoryboard storyboardWithName:name bundle:nil];
        [storyboards setObject:storyboard forKey:name];
    }
    return storyboard;
}

+ (void)setStoryboard:(UIStoryboard *)storyboard named:(NSString *)name {
    if (storyboard) {
        [storyboards setObject:storyboard forKey:name];
    }
}

- (void)present:(BOOL)animated {
    [UIWindow mainWindow].rootViewController = [self instantiateInitialViewController];
}

@end

@implementation UIViewController (WLNavigation)

+ (instancetype)instantiateWithIdentifier:(NSString *)identifier storyboard:(UIStoryboard *)storyboard {
	id controller = [storyboard instantiateViewControllerWithIdentifier:identifier];
	if ([controller isKindOfClass:self]) {
		return controller;
	}
	return nil;
}

+ (instancetype)instantiate:(UIStoryboard *)storyboard {
	return [self instantiateWithIdentifier:NSStringFromClass(self) storyboard:storyboard];
}

- (void)requestAuthorizationForPresentingEntry:(WLEntry *)entry completion:(WLBooleanBlock)completion {
    if (completion) completion(YES);
}

- (BOOL)isTopViewController {
    return self.navigationController.topViewController == self;
}

- (void)pushViewController:(UIViewController *)controller animated:(BOOL)animated {
    if ([self isTopViewController]) {
        [self.navigationController pushViewController:controller animated:animated];
    }
}

- (void)pushViewControllerNextToCurrent:(UIViewController*)controller animated:(BOOL)animated {
    [self pushViewController:controller nextToViewController:self animated:animated];
}

- (void)pushViewControllerNextToRootViewController:(UIViewController *)controller animated:(BOOL)animated {
    [self pushViewController:controller nextToViewController:[self.navigationController.viewControllers firstObject] animated:animated];
}

- (void)pushViewController:(UIViewController *)controller
      nextToViewController:(UIViewController *)nextToController
                  animated:(BOOL)animated {
    NSMutableArray* controllers = [NSMutableArray array];
    
    for (UIViewController* ctrlr in self.navigationController.viewControllers) {
        [controllers addObject:ctrlr];
        if (ctrlr == nextToController) {
            [controllers addObject:controller];
            break;
        }
    }
    
    [self.navigationController setViewControllers:[NSArray arrayWithArray:controllers] animated:animated];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (IBAction)back:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)backSegue:(UIStoryboardSegue *)unwindSegue {
    
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
    for (UIViewController* _controller in self.viewControllers) {
        if ([_controller isKindOfClass:[viewController class]]) {
            if (_controller != self.topViewController) {
                [self popToViewController:_controller animated:animated];
            }
            return;
        }
    }
    [self pushViewController:viewController animated:animated];
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
