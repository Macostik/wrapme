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
#import "WLStillPictureViewController.h"
#import "UIView+QuatzCoreAnimations.h"

@interface WLActionViewController ()

@property (strong, nonatomic) UIViewController *childViewController;

@end

@implementation WLActionViewController

+ (id)instanceByClass:(Class)class {
    WLActionViewController *actionVC = [class new];
    
    return actionVC;
}

+ (id)addViewControllerByClass:(Class)class toParentViewController:(UIViewController *)viewController {
   id childViewController = [self addViewControllerByClass:class withEntry:nil toParentViewController:viewController];
    
    return childViewController;
}

+ (id)addViewControllerByClass:(Class)class withEntry:(id)entry toParentViewController:(UIViewController *)viewController {
    WLActionViewController *actionVC = [self instanceByClass:self];
    id childViewController = [self instanceByClass:class];
    [childViewController setEntry:entry];
    actionVC.childViewController = childViewController;
    [self addChildViewController:actionVC toParentViewController:viewController];
    
    return childViewController;
}

+ (id)addViewControllerAsDelegateByClass:(Class)class toParentViewController:(UIViewController *)viewController {
    id childViewController = [self addViewControllerByClass:class toParentViewController:viewController];
    __block WLStillPictureViewController *stillPictureVC = (WLStillPictureViewController *)viewController;
    stillPictureVC.delegate = childViewController;
    
    [childViewController setCompletionBlock:^{
        [stillPictureVC dismissViewControllerAnimated:YES completion:NULL];
    }];
    
    return childViewController;
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
    self.view.backgroundColor = [UIColor colorWithWhite:.0 alpha:0.5];
    
    if (self.childViewController) {
        [self willAddChildViewController:self.childViewController];
    }
    [[WLKeyboard keyboard] addReceiver:self];
}

- (void)dismiss {
    [self removeAnimateViewsFromSuperView];
    [self removeFromParentViewController];
}

- (void)removeAnimateViewsFromSuperView {
    [UIView animateWithDuration:1.0 animations:^{
        self.childViewController.view.transform = CGAffineTransformMakeTranslation(.0, self.view.height);
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
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

@implementation  UIViewController (WLActionViewController)

- (void)setEntry:(id)entry {
    if ([self respondsToSelector:@selector(setWrap:)]) {
        [self performSelector:@selector(setWrap:) withObject:entry];
    } else if ([self respondsToSelector:@selector(setCandy:)]) {
        [self performSelector:@selector(setCandy:) withObject:entry];
    }
}

@end