//
//  WLEntryHierarchyPresenter.m
//  meWrap
//
//  Created by Ravenpod on 4/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLHierarchicalEntryPresenter.h"
#import "WLToast.h"

@implementation WLHierarchicalEntryPresenter

+ (void)presentEntry:(Entry *)entry inNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated {
    NSMutableArray *viewControllers = [self viewControllersForEntry:entry inNavigationController:navigationController];
    [viewControllers insertObject:navigationController.viewControllers.firstObject atIndex:0];
    [navigationController setViewControllers:viewControllers animated:animated];
}

+ (NSMutableArray *)viewControllersForEntry:(Entry *)entry inNavigationController:(UINavigationController*)navigationController {
    NSMutableArray *viewControllers = [NSMutableArray array];
    Entry *currentEntry = entry;
    while (currentEntry.valid) {
        UIViewController *viewController = [currentEntry viewControllerWithNavigationController:navigationController];
        if (viewController) {
            [viewControllers addObject:viewController];
            if (currentEntry != entry) {
                [entry configureViewController:viewController fromContainer:currentEntry];
            }
        }
        currentEntry = currentEntry.container;
    }
    
    if (![viewControllers count]) {
        [WLToast showWithMessage:@"data_invalid".ls];
    }
    
    return [[[viewControllers reverseObjectEnumerator] allObjects] mutableCopy];
}

@end
