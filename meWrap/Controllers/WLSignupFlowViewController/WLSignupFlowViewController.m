//
//  WLSignUpViewController.m
//  meWrap
//
//  Created by Ravenpod on 19.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSignupFlowViewController.h"
#import "WLProfileInformationViewController.h"
#import "WLPhoneViewController.h"
#import "WLNavigationHelper.h"
#import "WLEmailViewController.h"
#import "WLPhoneViewController.h"
#import "WLEmailConfirmationViewController.h"
#import "WLLinkDeviceViewController.h"
#import "WLTelephony.h"
#import "WLActivationViewController.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLAuthorizationRequest.h"

@interface WLSignupFlowViewController () <UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topHeaderConstraint;

@property (strong, nonatomic) NSMutableSet* stepViewControllers;

@property (weak, nonatomic) UIButton *nextButton;

@end

@implementation WLSignupFlowViewController

- (void)viewDidLoad {
	[super viewDidLoad];
    self.stepViewControllers = [NSMutableSet set];
    UINavigationController *navigationController = [self.childViewControllers lastObject];
    [navigationController setDelegate:self];
    if (self.registrationNotCompleted) {
        [self completeSignup:navigationController];
    } else {
        [self configureSignupFlow:navigationController];
    }
}

- (void)completeSignup:(UINavigationController*)navigationController {
    __weak WLProfileInformationViewController* profileStep = [self stepViewController:@"WLProfileInformationViewController"];
    [profileStep setSuccessStatusBlock:^WLSignupStepViewController *{
        [[UIStoryboard storyboardNamed:WLMainStoryboard] present:YES];
        return nil;
    }];
    navigationController.viewControllers = @[profileStep];
}

- (id)stepViewController:(NSString*)identifier {
    id controller = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    if (controller) {
        [self.stepViewControllers addObject:controller];
    }
    return controller;
}

- (void)configureSignupFlow:(UINavigationController*)navigationController {
    
    __weak WLEmailViewController* emailStep = [self stepViewController:@"WLEmailViewController"];
    __weak WLPhoneViewController* phoneStep = [self stepViewController:@"WLPhoneViewController"];
    __weak WLActivationViewController* verificationStep = [self stepViewController:@"WLActivationViewController"];
    __weak WLLinkDeviceViewController* linkDeviceStep = [self stepViewController:@"WLLinkDeviceViewController"];
    __weak WLEmailConfirmationViewController *emailConfirmationStep = [self stepViewController:@"WLEmailConfirmationViewController"];
    __weak WLSignupStepViewController* verificationSuccessStep = [self stepViewController:@"WLVerificationSuccessViewController"];
    __weak WLSignupStepViewController* verificationFailureStep = [self stepViewController:@"WLVerificationFailureViewController"];
    __weak WLSignupStepViewController* linkDeviceSuccessStep = [self stepViewController:@"WLLinkDeviceSuccessViewController"];
    __weak WLSignupStepViewController* emailConfirmationSuccessStep = [self stepViewController:@"WLEmailConfirmationSuccessViewController"];
    __weak WLProfileInformationViewController* profileStep = [self stepViewController:@"WLProfileInformationViewController"];
    
    navigationController.viewControllers = @[emailStep];
    // final completion block
    
    WLSignupStepCompletionBlock completeSignUp = ^WLSignupStepViewController *{
        [[UIStoryboard storyboardNamed:WLMainStoryboard] present:YES];
        return nil;
    };
    
    // profile subflow (will be skipped if is not required)
    
    WLSignupStepCompletionBlock profileStepBlock = ^WLSignupStepViewController *{
        WLUser *user = [WLUser currentUser];
        if (user.isSignupCompleted) {
            return completeSignUp();
        } else {
            [profileStep setSuccessStatusBlock:completeSignUp];
            return profileStep;
        }
    };
    
    // verification subflow
    
    WLSignupVerificationStepBlock verificationStepBlock = ^WLSignupStepViewController * (WLSignupStepCompletionBlock seccessBlock, BOOL shouldSignIn) {
        [phoneStep setSuccessStatusBlock:^WLSignupStepViewController *{
            [verificationStep setSuccessStatusBlock:^WLSignupStepViewController *{
                [verificationSuccessStep setSuccessStatusBlock:^WLSignupStepViewController *{
                    if (seccessBlock) {
                        return seccessBlock();
                    } else {
                        return nil;
                    }
                }];
                return verificationSuccessStep;
            }];
            [verificationStep setFailureStatusBlock:^WLSignupStepViewController *{
                [verificationFailureStep setFailureStatusBlock:^WLSignupStepViewController *{
                    return verificationStep;
                }];
                [verificationFailureStep setCancelStatusBlock:^WLSignupStepViewController *{
                    return phoneStep;
                }];
                return verificationFailureStep;
            }];
            verificationStep.shouldSignIn = shouldSignIn;
            return verificationStep;
        }];
        [phoneStep setCancelStatusBlock:^WLSignupStepViewController *{
            return emailStep;
        }];
        return phoneStep;
    };
    
    // device linking subflow
    
    WLSignupLinkDeviceStepBlock linkDeviceBlock = ^WLSignupStepViewController *(BOOL shouldSendPasscode){
        [linkDeviceStep setSuccessStatusBlock:^WLSignupStepViewController *{
            [linkDeviceSuccessStep setSuccessStatusBlock:^WLSignupStepViewController *{
                return profileStepBlock();
            }];
            return linkDeviceSuccessStep;
        }];
        if (shouldSendPasscode) {
            [linkDeviceStep sendPasscode];
        }
        return linkDeviceStep;
    };
    
    
    // second device signup subflow (different for phone and wifi device)
    
    WLSignupStepCompletionBlock secondDeviceBlock = ^WLSignupStepViewController *{
        if ([WLTelephony hasPhoneNumber] || ![WLWhoIs sharedInstance].containsPhoneDevice) {
            return verificationStepBlock(^WLSignupStepViewController *{
                return linkDeviceBlock(NO);
            }, NO);
        } else {
            return linkDeviceBlock(YES);
        }
    };
    
    // first sign up flow
    
    [emailStep setCompletionBlock:^WLSignupStepViewController *{
        return verificationStepBlock(^WLSignupStepViewController *{
            return profileStepBlock();
        }, YES);
    } forStatus:WLEmailStepStatusVerification];
    
    // second device witn unconfirmed e-mail flow
    
    [emailStep setCompletionBlock:^WLSignupStepViewController *{
        [emailConfirmationStep setSuccessStatusBlock:^WLSignupStepViewController *{
            [emailConfirmationSuccessStep setSuccessStatusBlock:secondDeviceBlock];
            return emailConfirmationSuccessStep;
        }];
        return emailConfirmationStep;
    } forStatus:WLEmailStepStatusUnconfirmedEmail];
    
    // second device witn confirmed e-mail flow
    
    [emailStep setCompletionBlock:secondDeviceBlock forStatus:WLEmailStepStatusLinkDevice];
    
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [[[self.childViewControllers lastObject] topViewController] preferredStatusBarStyle];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    __weak typeof(self)weakSelf = self;
    [UIView performAnimated:animated animation:^{
        if ([viewController isKindOfClass:[WLSignupStepViewController class]]) {
            weakSelf.headerView.alpha = 1.0f;
        } else {
            weakSelf.headerView.alpha = 0.0f;
        }
    }];
}

@end
