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
    self.flowNavigationController.viewControllers = @[[WLProfileInformationViewController instantiate:self.storyboard]];
}

- (void)configureSignupFlow {
    UIStoryboard* storyboard = self.storyboard;
    
    WLEmailViewController* emailViewController = [self.flowNavigationController.viewControllers lastObject];
    WLPhoneViewController* phoneViewController = [WLPhoneViewController instantiate:storyboard];
    WLActivationViewController* verificationViewController = [WLActivationViewController instantiate:storyboard];
    WLLinkDeviceViewController* linkDeviceViewController = [WLLinkDeviceViewController instantiate:storyboard];
    WLEmailConfirmationViewController *confirmationViewController = [WLEmailConfirmationViewController instantiate:storyboard];
    
    WLSignupStepViewController* verificationSuccessViewController = [storyboard instantiateViewControllerWithIdentifier:@"WLVerificationSuccessViewController"];
    WLSignupStepViewController* verificationFailureViewController = [storyboard instantiateViewControllerWithIdentifier:@"WLVerificationFailureViewController"];
    WLSignupStepViewController* linkDeviceSuccessViewController = [storyboard instantiateViewControllerWithIdentifier:@"WLLinkDeviceSuccessViewController"];
    WLSignupStepViewController* emailConfirmationSuccessViewController = [storyboard instantiateViewControllerWithIdentifier:@"WLEmailConfirmationSuccessViewController"];
    
    WLProfileInformationViewController* profileViewController = [WLProfileInformationViewController instantiate:storyboard];
    
    NSMutableSet *controllers = self.stepViewControllers;
    [controllers addObject:emailViewController];
    [controllers addObject:phoneViewController];
    [controllers addObject:verificationViewController];
    [controllers addObject:linkDeviceViewController];
    [controllers addObject:confirmationViewController];
    [controllers addObject:verificationSuccessViewController];
    [controllers addObject:verificationFailureViewController];
    [controllers addObject:linkDeviceSuccessViewController];
    [controllers addObject:emailConfirmationSuccessViewController];
    [controllers addObject:profileViewController];
    
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
