//
//  WLTapBarStoryboardTransition.m
//  WrapLive
//
//  Created by Yura Granchenko on 11/06/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLTapBarStoryboardTransition.h"
#import "UIView+Extentions.h"

@interface WLTapBarStoryboardTransition ()

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) NSMutableArray *controllers;

@end

@implementation WLTapBarStoryboardTransition

+ (instancetype)sharedStroryboard {
    static WLTapBarStoryboardTransition *_sharedTransition = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedTransition = [WLTapBarStoryboardTransition new];
        _sharedTransition.controllers = [NSMutableArray array];
    });
    
    return _sharedTransition;
}

- (IBAction)addChild:(UIButton *)sender {
    NSMutableArray *bufferControllers = [WLTapBarStoryboardTransition sharedStroryboard].controllers;
    UIViewController *toViewController = self.destinationViewController;
    UIViewController *fromViewController = self.sourceViewController;
    
    UIViewController *viewController = [self controllerRelativeDestinationViewController:toViewController];
    if (viewController == nil) {
        viewController = toViewController;
        [bufferControllers addObject:viewController];
    } else {
        toViewController = viewController;
    }
    toViewController.view.frame = self.containerView.bounds;
    
    [self.containerView addSubview:toViewController.view];
    [self.containerView makeResizibleSubview:toViewController.view];
    [fromViewController addChildViewController:toViewController];
    [toViewController didMoveToParentViewController:fromViewController];
}

- (UIViewController *)controllerRelativeDestinationViewController:(UIViewController *)destinationViewController {
    for (UIViewController *viewController in [WLTapBarStoryboardTransition sharedStroryboard].controllers) {
        if ([destinationViewController.class isEqual:viewController.class]) {
            return viewController;
        }
    }
    return nil;
}

@end
