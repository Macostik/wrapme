//
//  WLNotificationEntryPresenter.m
//  wrapLive
//
//  Created by Sergey Maximenko on 4/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLNotificationEntryPresenter.h"
#import "WLNavigationHelper.h"

@implementation WLNotificationEntryPresenter

+ (void)presentEntry:(WLEntry *)entry inNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated {
    NSMutableArray *controllers = [NSMutableArray array];
    
    UIViewController *rootViewController = navigationController.viewControllers.firstObject;
    if (rootViewController) {
        [controllers addObject:rootViewController];
    }
    
    UIViewController *entryViewController = [entry viewControllerWithNavigationController:navigationController];
    if (entryViewController) {
        [controllers addObject:entryViewController];
    }
    
    [navigationController setViewControllers:controllers animated:animated];
}

@end
