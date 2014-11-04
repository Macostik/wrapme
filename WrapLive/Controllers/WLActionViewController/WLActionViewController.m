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
#import "WLCreateWrapViewController.h"
#import "UIView+QuatzCoreAnimations.h"

static NSString *const wlActionViewController = @"WLActionViewController";

@interface WLActionViewController ()

@property (strong, nonatomic) UIViewController *childViewController;

@end

@implementation WLActionViewController

+ (id)instanceViewController:(UIViewController *)viewController {
    WLActionViewController *actionVC = [viewController.storyboard instantiateViewControllerWithIdentifier:wlActionViewController];
    
    return actionVC;
}

+ (void)addEditWrapViewControllerWithWrap:(WLWrap *)wrap toParentViewController:(UIViewController *)viewController {
    WLActionViewController *actionVC = [self instanceViewController:viewController];
    id editViewController = [WLEditWrapViewController new];
    actionVC.childViewController = editViewController;
    [editViewController setWrap:wrap];
    [self addChildViewController:actionVC toParentViewController:viewController];
}

+ (void)addCandyViewControllerWithCandy:(WLCandy *)candy toParentViewController:(UIViewController *)viewController {
    WLActionViewController *actionVC = [self instanceViewController:viewController];
     id candyViewController = [WLReportCandyViewController new];
    actionVC.childViewController = candyViewController;
    [candyViewController setCandy:candy];
    [self addChildViewController:actionVC toParentViewController:viewController];
}

+ (void)addCreateWrapViewControllerToParentViewController:(UIViewController *)viewController {
    WLActionViewController *actionVC = [self instanceViewController:viewController];
    id createWrapViewController = [WLCreateWrapViewController new];
    actionVC.childViewController = createWrapViewController;
    [self addChildViewController:actionVC toParentViewController:viewController];
}

- (void)didAddChildViewController:(UIViewController *)viewController {
    [self addChildViewController:viewController];
    viewController.view.center = CGPointMake(self.view.width/2, self.view.height/2);
    [self.view addSubview:viewController.view];
    [self didMoveToParentViewController:viewController];
}

+ (void)addChildViewController:(UIViewController *)viewController toParentViewController:(UIViewController *)parentVC {
    [parentVC addChildViewController:viewController];
    viewController.view.frame = parentVC.view.bounds;
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    viewController.view.center = CGPointMake(parentVC.view.width/2, parentVC.view.height/2);
    [parentVC.view addSubview:viewController.view];
    [parentVC didMoveToParentViewController:viewController];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.childViewController) {
        [self didAddChildViewController:self.childViewController];
    }
    [[WLKeyboard keyboard] addReceiver:self];
}

- (void)dismiss {
    CGFloat duration = 0.33f;
    [UIView animateWithDuration:duration animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(.0f, self.view.height);
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];
}


#pragma mark - WLKeyboardBroadcastReceiver

- (void)keyboardWillShow:(WLKeyboard *)keyboard {
    CGFloat offset = self.childViewController.view.y - (self.view.height - keyboard.height)/2 + self.childViewController.view.height/2;
    [keyboard performAnimation:^{
        self.childViewController.view.transform = CGAffineTransformMakeTranslation(0, -offset);
    }];
}

- (void)keyboardWillHide:(WLKeyboard*)keyboard {
    [keyboard performAnimation:^{
        self.childViewController.view.transform = CGAffineTransformIdentity;
    }];
}

@end