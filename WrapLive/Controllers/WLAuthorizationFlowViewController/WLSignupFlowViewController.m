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

@interface WLSignupFlowViewController () <UINavigationControllerDelegate, WLAuthorizationSceneViewControllerDelegate>

@property (weak, nonatomic) UINavigationController* flowNavigationController;
@property (weak, nonatomic) IBOutlet UIView *headerView;

@end

@implementation WLSignupFlowViewController

- (void)viewDidLoad {
	[super viewDidLoad];
    self.flowNavigationController = [self.childViewControllers lastObject];
    self.flowNavigationController.delegate = self;
    if (self.registrationNotCompleted) {
        self.flowNavigationController.viewControllers = @[[WLProfileInformationViewController instantiate:self.storyboard]];
    } else {
        WLEmailViewController* emailViewController = [self.flowNavigationController.viewControllers lastObject];
        WLPhoneViewController* phoneViewController = [WLPhoneViewController instantiate:self.storyboard];
        WLActivationViewController* verificationViewController = [WLActivationViewController instantiate:self.storyboard];
        WLLinkDeviceViewController* linkDeviceViewController = [WLLinkDeviceViewController instantiate:self.storyboard];
        WLEmailConfirmationViewController *confirmationViewController = [WLEmailConfirmationViewController instantiate:self.storyboard];
        
        WLSignupStepViewController* verificationSuccessViewController = [WLSignupStepViewController instantiateWithIdentifier:@"WLVerificationSuccessViewController" storyboard:self.storyboard];
        WLSignupStepViewController* verificationFailureViewController = [WLSignupStepViewController instantiateWithIdentifier:@"WLVerificationFailureViewController" storyboard:self.storyboard];
        WLSignupStepViewController* linkDeviceSuccessViewController = [WLSignupStepViewController instantiateWithIdentifier:@"WLLinkDeviceSuccessViewController" storyboard:self.storyboard];
        WLSignupStepViewController* emailConfirmationSuccessViewController = [WLSignupStepViewController instantiateWithIdentifier:@"WLEmailConfirmationSuccessViewController" storyboard:self.storyboard];
        WLProfileInformationViewController* profileViewController = [WLProfileInformationViewController instantiate:self.storyboard];
        
        [emailViewController setViewController:phoneViewController forStatus:WLEmailViewControllerCompletionStatusVerification];
        [emailViewController setViewController:linkDeviceViewController forStatus:WLEmailViewControllerCompletionStatusLinkDevice];
        [emailViewController setViewController:confirmationViewController forStatus:WLEmailViewControllerCompletionStatusUnconfirmedEmail];
        
        [phoneViewController setSuccessViewController:verificationViewController];
        
        [verificationViewController setSuccessViewController:verificationSuccessViewController];
        
        [verificationViewController setFailureViewController:verificationFailureViewController];
        
        [verificationSuccessViewController setSuccessViewController:profileViewController];
        
        [verificationFailureViewController setFailureViewController:verificationViewController];
        
        [verificationFailureViewController setCancelViewController:phoneViewController];
        
        [linkDeviceViewController setSuccessViewController:linkDeviceSuccessViewController];
        
        [linkDeviceSuccessViewController setSuccessViewController:profileViewController];
        
        [confirmationViewController setSuccessViewController:emailConfirmationSuccessViewController];
    }
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return self.headerView.bounds.size.height;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(WLSignupStepViewController *)viewController animated:(BOOL)animated {
    viewController.delegate = self;
}

@end
