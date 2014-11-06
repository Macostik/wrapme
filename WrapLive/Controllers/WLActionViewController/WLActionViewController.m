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
#import "WLPickerViewController.h"
#import "UIView+QuatzCoreAnimations.h"

static NSString *const wlActionViewController = @"WLActionViewController";

@interface WLActionViewController ()

@property (strong, nonatomic) UIViewController *childViewController;

@end

@implementation WLActionViewController

+ (id)instance {
    WLActionViewController *actionVC = [[UIStoryboard storyboardNamed:WLMainStoryboard]
                                        instantiateViewControllerWithIdentifier:wlActionViewController];
    
    return actionVC;
}

+ (void)addEditWrapViewControllerWithWrap:(WLWrap *)wrap toParentViewController:(UIViewController *)viewController {
    WLActionViewController *actionVC = [self instance];
    id editViewController = [WLEditWrapViewController new];
    actionVC.childViewController = editViewController;
    [editViewController setWrap:wrap];
    [self addChildViewController:actionVC toParentViewController:viewController];
}

+ (void)addCandyViewControllerWithCandy:(WLCandy *)candy toParentViewController:(UIViewController *)viewController {
    WLActionViewController *actionVC = [self instance];
     id candyViewController = [WLReportCandyViewController new];
    actionVC.childViewController = candyViewController;
    [candyViewController setCandy:candy];
    [self addChildViewController:actionVC toParentViewController:viewController];
}

+ (void)addCreateWrapViewControllerToParentViewController:(UIViewController *)viewController {
    WLActionViewController *actionVC = [self instance];
    id createWrapViewController = [WLCreateWrapViewController new];
    actionVC.childViewController = createWrapViewController;
    [self addChildViewController:actionVC toParentViewController:viewController];
}

- (void)willAddChildViewController:(UIViewController *)viewController {
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
        [self willAddChildViewController:self.childViewController];
    }
    [[WLKeyboard keyboard] addReceiver:self];
}

- (void)dismiss {
    [UIView animateWithDuration:1.0f animations:^{
        self.childViewController.view.y = self.view.height;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];
}

- (void)willUpdateBottomInset:(CGFloat)bottomInset forController:(UIViewController *)viewController {
    viewController.view.transform = CGAffineTransformMakeTranslation(.0, -bottomInset);
}

- (void)willUpdateTopInset:(CGFloat)topInset forController:(UIViewController *)viewController {
    viewController.view.transform = CGAffineTransformMakeTranslation(.0, topInset);
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