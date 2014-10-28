//
//  WLActionViewController.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/27/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNavigation.h"
#import "WLActionViewController.h"
#import "UIView+Shorthand.h"
#import "WLEditWrapViewController.h"
#import "WLReportCandyViewController.h"
#import "UIView+QuatzCoreAnimations.h"

static NSString *const wlActionViewController = @"WLActionViewController";

@implementation WLActionViewController

+ (void)addEditWrapViewControllerWithWrap:(WLWrap *)wrap toParentViewController:(UIViewController *)viewController {
    WLActionViewController *actionVC = [viewController.storyboard instantiateViewControllerWithIdentifier:wlActionViewController];
    [self addChildViewController:actionVC toParentViewController:viewController];;
    WLEditWrapViewController *editWrapVC = [[WLEditWrapViewController alloc] init];
    editWrapVC.wrap = wrap;
    [self addChildViewController:editWrapVC toParentViewController:actionVC];
}

+ (void)addCandyViewControllerWithCandy:(WLCandy *)candy toParentViewController:(UIViewController *)viewController {
    WLActionViewController *actionVC = [viewController.storyboard instantiateViewControllerWithIdentifier:wlActionViewController];
    [self addChildViewController:actionVC toParentViewController:viewController];
    WLReportCandyViewController *reportCandyVC = [[WLReportCandyViewController alloc] init];
    reportCandyVC.candy = candy;
    [self addChildViewController:reportCandyVC toParentViewController:actionVC];
    
}

+ (void)addChildViewController:(UIViewController *)viewController toParentViewController:(UIViewController *)parentVC {
    [parentVC addChildViewController:viewController];
    viewController.view.frame = parentVC.view.bounds;
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [parentVC.view addSubview:viewController.view];
    [parentVC didMoveToParentViewController:viewController];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.view.window.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
    self.view.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
    id vc = self.childViewControllers.firstObject;
    if (vc) {
        [vc contentView].center = self.view.center;
    }
}

@end