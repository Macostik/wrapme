//
//  WLChronologicalEntryPresenter.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLChronologicalEntryPresenter.h"

@implementation WLChronologicalEntryPresenter

+ (void)presentEntry:(WLEntry *)entry inNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated {
    UIViewController *controller = nil;
    WLEntry *currentEntry = entry;
    while (currentEntry.valid) {
        controller = [currentEntry viewControllerWithNavigationController:navigationController];
        if (controller) {
            if (currentEntry != entry) {
                [entry configureViewController:controller fromContainingEntry:currentEntry];
            }
            currentEntry = nil;
        } else {
            currentEntry = currentEntry.containingEntry;
        }
    }
    
    if (controller) {
        if ([navigationController.viewControllers containsObject:controller]) {
            if (navigationController.topViewController != controller) {
                [navigationController popToViewController:controller animated:animated];
            }
        } else {
            [navigationController pushViewController:controller animated:animated];
        }
        
    }
}

@end
