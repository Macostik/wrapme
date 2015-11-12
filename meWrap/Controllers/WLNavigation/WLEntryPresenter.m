//
//  WLEntryPresenter.m
//  meWrap
//
//  Created by Ravenpod on 4/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntryPresenter.h"
#import "WLNavigationHelper.h"
#import "WLToast.h"
#import "WLWrapViewController.h"
#import "WLCandyViewController.h"
#import "WLChatViewController.h"
#import "WLHistoryViewController.h"

@implementation WLEntryPresenter

+ (void)presentEntry:(Entry *)entry animated:(BOOL)animated {
    [self presentEntry:entry inNavigationController:[UINavigationController mainNavigationController] animated:animated];
}

+ (void)presentEntry:(Entry *)entry inNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated {
    
}

+ (void)presentEntryRequestingAuthorization:(Entry *)entry animated:(BOOL)animated {
    [self presentEntryRequestingAuthorization:entry inNavigationController:[UINavigationController mainNavigationController] animated:animated];
}

+ (void)presentEntryRequestingAuthorization:(Entry *)entry inNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated {
    UIViewController *presentedViewController = [navigationController presentedViewController];
    if (presentedViewController) {
        [presentedViewController requestAuthorizationForPresentingEntry:entry completion:^(BOOL flag) {
            if (flag) {
                [navigationController dismissViewControllerAnimated:NO completion:^{
                    [self presentEntry:entry inNavigationController:navigationController animated:animated];
                }];
            }
        }];
    } else {
        [self presentEntry:entry inNavigationController:navigationController animated:animated];
    }
}

@end

@implementation UIViewController (WLEntryPresenter)

- (void)requestAuthorizationForPresentingEntry:(Entry *)entry completion:(WLBooleanBlock)completion {
    if (completion) completion(YES);
}

@end

@implementation Entry (WLEntryPresenter)

- (UIViewController *)viewController {
    return nil;
}

- (UIViewController *)viewControllerWithNavigationController:(UINavigationController*)navigationController {
    for (UIViewController *viewController in navigationController.viewControllers) {
        if ([self isValidViewController:viewController]) return viewController;
    }
    return [self viewController];
}

- (UIViewController *)recursiveViewControllerWithNavigationController:(UINavigationController *)navigationController {
    UIViewController *controller = nil;
    Entry *currentEntry = self;
    while (currentEntry.valid) {
        controller = [currentEntry viewControllerWithNavigationController:navigationController];
        if (controller) {
            if (currentEntry != self) {
                [self configureViewController:controller fromContainer:currentEntry];
            }
            currentEntry = nil;
        } else {
            currentEntry = currentEntry.container;
        }
    }
    return controller;
}

- (BOOL)isValidViewController:(UIViewController *)controller {
    return NO;
}

- (void)configureViewController:(UIViewController*)controller fromContainer:(Entry *)container {
}

@end

@implementation Candy (WLEntryPresenter)

- (UIViewController *)viewController {
    WLHistoryViewController* controller = [WLHistoryViewController instantiate:[UIStoryboard storyboardNamed:WLMainStoryboard]];
    controller.candy = self;
    return controller;
}

- (BOOL)isValidViewController:(UIViewController *)controller {
    if (![controller isKindOfClass:[WLHistoryViewController class]]) return NO;
    if ([(WLHistoryViewController*)controller candy] != self) return NO;
    return YES;
}

@end

@implementation Message (WLEntryPresenter)

- (UIViewController *)viewController {
    Wrap *wrap = self.wrap;
    if (wrap) {
        WLWrapViewController* controller = [WLWrapViewController instantiate:[UIStoryboard storyboardNamed:WLMainStoryboard]];
        controller.wrap = wrap;
        controller.segment = WLWrapSegmentChat;
        return controller;
    }
    return nil;
}

- (BOOL)isValidViewController:(UIViewController *)controller {
    if (![controller isKindOfClass:[WLWrapViewController class]]) return NO;
    if ([(WLWrapViewController*)controller wrap] != self.wrap) return NO;
    if (([(WLWrapViewController*)controller segment] != WLWrapSegmentChat)) return NO;
    return YES;
}

@end

@implementation Wrap (WLEntryPresenter)

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

@implementation Comment (WLEntryPresenter)

- (void)configureViewController:(UIViewController *)controller fromContainer:(Entry *)container {
    if (container == self.candy) {
        WLHistoryViewController *candyViewController = (WLHistoryViewController *)controller;
        if (candyViewController.isViewLoaded) {
            [candyViewController showCommentView];
        } else {
            candyViewController.showCommentViewController = YES;
        }
    }
}

@end
