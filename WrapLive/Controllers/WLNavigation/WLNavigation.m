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
#import "UIAlertView+Blocks.h"

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

@implementation WLEntry (WLNavigation)

- (UIViewController *)viewController {
    return nil;
}

- (UIViewController *)viewControllerWithNavigationController:(UINavigationController*)navigationController {
    for (UIViewController *viewController in navigationController.viewControllers) {
        if ([self isValidViewController:viewController]) return viewController;
    }
    return [self viewController];
}

- (BOOL)isValidViewController:(UIViewController *)controller {
    return NO;
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
    NSMutableArray *viewControllers = [self newStackViewControllersWithNavigationController:navigationController];
    [viewControllers insertObject:navigationController.viewControllers.firstObject atIndex:0];
    [navigationController setViewControllers:viewControllers animated:animated];
}

- (NSMutableArray *)newStackViewControllersWithNavigationController:(UINavigationController*)navigationController {
    WLEntry *entry = self;
    NSMutableArray *viewControllers = [NSMutableArray array];
    while (entry) {
        UIViewController *viewController = [entry viewControllerWithNavigationController:navigationController];
        if (viewController) {
            [viewControllers addObject:viewController];
        }
        entry = entry.containingEntry;
    }
    
    return [[[viewControllers reverseObjectEnumerator] allObjects] mutableCopy];
}

- (void)presentViewControllerWithoutLostData {
    UINavigationController *navigationController = [UINavigationController mainNavigationController];
    if ([navigationController presentedViewController]) {
        [UIAlertView showWithTitle:WLLS(@"Unsaved photo")
                           message:WLLS(@"You are editing a photo and it is not saved yet. Are you sure you want to leave this screen?")
                            cancel:WLLS(@"Cancel")
                            action:WLLS(@"Continue")
                        completion:^{
                            [navigationController dismissViewControllerAnimated:YES completion:nil];
                            [self present];
                        }];
    } else {
        [self present:NO];
    }
}

@end

@implementation WLCandy (WLNavigation)

- (UIViewController *)viewController {
    WLCandyViewController* controller = [WLCandyViewController instantiate:[UIStoryboard storyboardNamed:WLMainStoryboard]];
    controller.candy = self;
    return controller;
}

- (BOOL)isValidViewController:(UIViewController *)controller {
    if (![controller isKindOfClass:[WLCandyViewController class]]) return NO;
    if ([(WLCandyViewController*)controller candy] != self) return NO;
    return YES;
}

@end

@implementation WLMessage (WLNavigation)

- (UIViewController *)viewController {
    WLChatViewController* controller = [WLChatViewController instantiate:[UIStoryboard storyboardNamed:WLMainStoryboard]];
    controller.wrap = self.wrap;
    return controller;
}

- (BOOL)isValidViewController:(UIViewController *)controller {
    if (![controller isKindOfClass:[WLChatViewController class]]) return NO;
    if ([(WLChatViewController*)controller wrap] != self.wrap) return NO;
    return YES;
}

@end

@implementation WLWrap (WLNavigation)

- (UIViewController *)viewController {
    WLWrapViewController* controller = [WLWrapViewController instantiate:[UIStoryboard storyboardNamed:WLMainStoryboard]];
    controller.wrap = self;
    return controller;
}

- (BOOL)isValidViewController:(UIViewController *)controller {
    if (![controller isKindOfClass:[WLWrapViewController class]]) return NO;
    if ([(WLWrapViewController*)controller wrap] != self) return NO;
    return YES;
}

@end
