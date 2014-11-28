//
//  WLSignUpViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLSignupFlowViewController.h"
#import "WLProfileInformationViewController.h"
#import "WLPhoneViewController.h"
#import "WLNavigation.h"
#import "WLEmailViewController.h"
#import "WLPhoneViewController.h"
#import "WLEmailConfirmationViewController.h"
#import "WLLinkDeviceViewController.h"
#import "WLTelephony.h"
#import "WLActivationViewController.h"

@interface WLSignupFlowViewController () <UINavigationControllerDelegate, WLSignupStepViewControllerDelegate>

@property (weak, nonatomic) UINavigationController* flowNavigationController;
@property (weak, nonatomic) IBOutlet UIView *headerView;

@property (strong, nonatomic) NSMutableSet* stepViewControllers;

@end

@implementation WLSignupFlowViewController

- (void)viewDidLoad {
	[super viewDidLoad];
    self.stepViewControllers = [NSMutableSet set];
    self.flowNavigationController = [self.childViewControllers lastObject];
    self.flowNavigationController.delegate = self;
    if (self.registrationNotCompleted) {
        [self completeSignup];
    } else {
        [self configureSignupFlow];
    }
}

- (void)completeSignup {
    self.flowNavigationController.viewControllers = @[[self stepViewController:@"WLProfileInformationViewController"]];
}

- (id)stepViewController:(NSString*)identifier {
    WLSignupStepViewController* controller = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    [self.stepViewControllers addObject:controller];
    return controller;
}

- (void)configureSignupFlow {
    
    WLEmailViewController* emailStep = [self stepViewController:@"WLEmailViewController"];
    self.flowNavigationController.viewControllers = @[emailStep];
    
    run_in_default_queue(^{
        WLPhoneViewController* phoneStep = [self stepViewController:@"WLPhoneViewController"];
        WLActivationViewController* verificationStep = [self stepViewController:@"WLActivationViewController"];
        WLLinkDeviceViewController* linkDeviceStep = [self stepViewController:@"WLLinkDeviceViewController"];
        WLEmailConfirmationViewController *emailConfirmationStep = [self stepViewController:@"WLEmailConfirmationViewController"];
        WLSignupStepViewController* verificationSuccessStep = [self stepViewController:@"WLVerificationSuccessViewController"];
        WLSignupStepViewController* verificationFailureStep = [self stepViewController:@"WLVerificationFailureViewController"];
        WLSignupStepViewController* linkDeviceSuccessStep = [self stepViewController:@"WLLinkDeviceSuccessViewController"];
        WLSignupStepViewController* emailConfirmationSuccessStep = [self stepViewController:@"WLEmailConfirmationSuccessViewController"];
        WLProfileInformationViewController* profileStep = [self stepViewController:@"WLProfileInformationViewController"];
        
        [emailStep setViewController:phoneStep forStatus:WLEmailStepStatusVerification];
        
        [emailStep setViewController:linkDeviceStep forStatus:WLEmailStepStatusLinkDevice];
        
        [emailStep setViewController:emailConfirmationStep forStatus:WLEmailStepStatusUnconfirmedEmail];
        
        [phoneStep setSuccessViewController:verificationStep];
        
        [verificationStep setSuccessViewController:verificationSuccessStep];
        
        [verificationStep setFailureViewController:verificationFailureStep];
        
        [verificationSuccessStep setSuccessViewController:profileStep];
        
        [verificationFailureStep setFailureViewController:verificationStep];
        
        [verificationFailureStep setCancelViewController:phoneStep];
        
        [linkDeviceStep setSuccessViewController:linkDeviceSuccessStep];
        
        [linkDeviceSuccessStep setSuccessViewController:profileStep];
        
        [emailConfirmationStep setSuccessViewController:emailConfirmationSuccessStep];
    });
    
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return self.headerView.bounds.size.height;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(WLSignupStepViewController *)viewController animated:(BOOL)animated {
    viewController.delegate = self;
}

- (void)signupStepViewControllerCompletedSignup:(WLSignupStepViewController *)controller {
    [UIWindow mainWindow].rootViewController = [[UIStoryboard storyboardNamed:WLMainStoryboard] instantiateInitialViewController];
}

@end
