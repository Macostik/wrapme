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

@end

@implementation WLTapBarStoryboardTransition

- (IBAction)addChild:(id)sender {
    UIViewController *toViewController = self.destinationViewController;
    UIViewController *fromViewController = self.sourceViewController;
    toViewController.view.frame = self.containerView.bounds;
    
    for (UIViewController *childViewController in [fromViewController childViewControllers]) {
        [childViewController.view removeFromSuperview];
        [childViewController removeFromParentViewController];
    }
    
    [self.containerView addSubview:toViewController.view];
    [fromViewController addChildViewController:toViewController];
    [toViewController didMoveToParentViewController:fromViewController];
}

@end
