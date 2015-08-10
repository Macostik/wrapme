//
//  WLChronologicalEntryPresenter.m
//  moji
//
//  Created by Ravenpod on 4/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLChronologicalEntryPresenter.h"

@implementation WLChronologicalEntryPresenter

+ (void)presentEntry:(WLEntry *)entry inNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated {
    UIViewController *controller = [entry recursiveViewControllerWithNavigationController:navigationController];
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
