//
//  WLNotificationEntryPresenter.m
//  meWrap
//
//  Created by Ravenpod on 4/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLNotificationEntryPresenter.h"

@implementation WLNotificationEntryPresenter

+ (void)presentEntry:(Entry *)entry inNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated {
    NSMutableArray *controllers = [NSMutableArray array];
    
    UIViewController *rootViewController = navigationController.viewControllers.firstObject;
    if (rootViewController) {
        [controllers addObject:rootViewController];
    }
    
    
    UIViewController *entryViewController = [entry recursiveViewControllerWithNavigationController:navigationController];
    
    if (entryViewController) {
        [controllers addObject:entryViewController];
    }
    
    [navigationController setViewControllers:controllers animated:animated];
}

@end
