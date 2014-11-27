//
//  WLAuthorizationSceneViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSignupStepViewController.h"
#import "WLNavigation.h"

@interface WLSignupStepViewController ()

@property (strong, nonatomic) NSMapTable* completionScenes;

@end

@implementation WLSignupStepViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (NSMapTable *)completionScenes {
    if (!_completionScenes) {
        _completionScenes = [NSMapTable strongToStrongObjectsMapTable];
    }
    return _completionScenes;
}

- (void)setViewController:(WLSignupStepViewController *)controller forStatus:(NSUInteger)status {
    [self.completionScenes setObject:controller forKey:@(status)];
}

- (void)setSuccessViewController:(WLSignupStepViewController*)controller {
    [self setViewController:controller forStatus:WLSignupStepStatusSuccess];
}

- (void)setFailureViewController:(WLSignupStepViewController*)controller {
    [self setViewController:controller forStatus:WLSignupStepStatusFailure];
}

- (void)setCancelViewController:(WLSignupStepViewController*)controller {
    [self setViewController:controller forStatus:WLSignupStepStatusCancel];
}

- (WLSignupStepViewController *)viewControllerForStatus:(NSUInteger)status {
    return [self.completionScenes objectForKey:@(status)];
}

- (BOOL)showViewControllerForStatus:(NSUInteger)status animated:(BOOL)animated {
    WLSignupStepViewController *controller = [self viewControllerForStatus:status];
    if (!controller) return NO;
    UINavigationController* navigationController = self.navigationController;
    if ([navigationController.viewControllers containsObject:controller]) {
        [navigationController popToViewController:controller animated:animated];
    } else {
        [navigationController pushViewController:controller animated:animated];
    }
    return YES;
}

- (BOOL)showSuccessViewControllerAnimated:(BOOL)animated {
    return [self showViewControllerForStatus:WLSignupStepStatusSuccess animated:animated];
}

- (BOOL)showFailureViewControllerAnimated:(BOOL)animated {
    return [self showViewControllerForStatus:WLSignupStepStatusFailure animated:animated];
}

- (BOOL)showCancelViewControllerAnimated:(BOOL)animated {
    return [self showViewControllerForStatus:WLSignupStepStatusCancel animated:animated];
}

- (IBAction)success:(id)sender {
    [self showViewControllerForStatus:WLSignupStepStatusSuccess animated:YES];
}

- (IBAction)failure:(id)sender {
    [self showViewControllerForStatus:WLSignupStepStatusFailure animated:YES];
}

- (IBAction)cancel:(id)sender {
    if (![self showViewControllerForStatus:WLSignupStepStatusCancel animated:YES]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)complete:(id)sender {
    [self complete];
}

- (void)complete {
    [UIWindow mainWindow].rootViewController = [[UIStoryboard storyboardNamed:WLMainStoryboard] instantiateInitialViewController];
}

@end
