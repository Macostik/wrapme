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
    for (UIViewController *controller in navigationController.viewControllers) {
        if ([entry isValidViewController:controller]) {
            if (controller != navigationController.topViewController) {
                [navigationController popToViewController:controller animated:animated];
            }
            return;
        }
    }
    UIViewController *controller = [entry viewController];
    if (controller) {
        [navigationController pushViewController:controller animated:animated];
    }
}

@end
