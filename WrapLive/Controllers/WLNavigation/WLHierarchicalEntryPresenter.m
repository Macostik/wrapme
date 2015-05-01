//
//  WLEntryHierarchyPresenter.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLHierarchicalEntryPresenter.h"
#import "WLToast.h"

@implementation WLHierarchicalEntryPresenter

+ (void)presentEntry:(WLEntry *)entry inNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated {
    NSMutableArray *viewControllers = [self viewControllersForEntry:entry inNavigationController:navigationController];
    [viewControllers insertObject:navigationController.viewControllers.firstObject atIndex:0];
    [navigationController setViewControllers:viewControllers animated:animated];
}

+ (NSMutableArray *)viewControllersForEntry:(WLEntry*)entry inNavigationController:(UINavigationController*)navigationController {
    NSMutableArray *viewControllers = [NSMutableArray array];
    WLEntry *currentEntry = entry;
    while (currentEntry.valid) {
        UIViewController *viewController = [currentEntry viewControllerWithNavigationController:navigationController];
        if (viewController) {
            [viewControllers addObject:viewController];
            if (currentEntry != entry) {
                [entry configureViewController:viewController fromContainingEntry:currentEntry];
            }
        }
        currentEntry = currentEntry.containingEntry;
    }
    
    if (![viewControllers count]) {
        [WLToast showWithMessage:WLLS(@"Data is not valid.")];
    }
    
    return [[[viewControllers reverseObjectEnumerator] allObjects] mutableCopy];
}

@end
