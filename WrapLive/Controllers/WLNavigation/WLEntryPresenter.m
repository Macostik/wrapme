//
//  WLEntryPresenter.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntryPresenter.h"
#import "WLNavigationHelper.h"
#import "WLToast.h"
#import "WLWrapViewController.h"
#import "WLCandyViewController.h"
#import "WLChatViewController.h"

@implementation WLEntryPresenter

+ (void)presentEntry:(WLEntry *)entry animated:(BOOL)animated {
    [self presentEntry:entry inNavigationController:[UINavigationController mainNavigationController] animated:animated];
}

+ (void)presentEntry:(WLEntry *)entry inNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated {
    
}

+ (void)presentEntryRequestingAuthorization:(WLEntry *)entry animated:(BOOL)animated {
    [self presentEntryRequestingAuthorization:entry inNavigationController:[UINavigationController mainNavigationController] animated:animated];
}

+ (void)presentEntryRequestingAuthorization:(WLEntry *)entry inNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated {
    UIViewController *presentedViewController = [navigationController presentedViewController];
    if (presentedViewController) {
        [presentedViewController requestAuthorizationForPresentingEntry:entry completion:^(BOOL flag) {
            if (flag) {
                [navigationController dismissViewControllerAnimated:YES completion:^{
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

- (void)requestAuthorizationForPresentingEntry:(WLEntry *)entry completion:(WLBooleanBlock)completion {
    if (completion) completion(YES);
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

- (void)configureViewController:(UIViewController*)controller fromContainingEntry:(WLEntry*)containingEntry {
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

@implementation WLComment (WLNavigation)

- (void)configureViewController:(UIViewController *)controller fromContainingEntry:(WLEntry *)containingEntry {
    if (containingEntry == self.candy) {
        WLCandyViewController *candyViewController = (WLCandyViewController *)controller;
        if (candyViewController.isViewLoaded) {
            [candyViewController showCommentView];
        } else {
            candyViewController.showCommentViewController = YES;
        }
    }
}

@end
