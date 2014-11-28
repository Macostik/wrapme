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

@interface WLSignupFlowViewController ()

@property (weak, nonatomic) IBOutlet UIView *headerView;

@property (strong, nonatomic) NSMutableSet* stepViewControllers;

@end

@implementation WLSignupFlowViewController

- (void)viewDidLoad {
	[super viewDidLoad];
    self.stepViewControllers = [NSMutableSet set];
    if (self.registrationNotCompleted) {
        [self completeSignup:[self.childViewControllers lastObject]];
    } else {
        [self configureSignupFlow:[self.childViewControllers lastObject]];
    }
}

- (void)completeSignup:(UINavigationController*)navigationController {
    __weak WLProfileInformationViewController* profileStep = [self stepViewController:@"WLProfileInformationViewController"];
    [profileStep setSuccessStatusBlock:^WLSignupStepViewController *{
        [UIWindow mainWindow].rootViewController = [[UIStoryboard storyboardNamed:WLMainStoryboard] instantiateInitialViewController];
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
    navigationController.viewControllers = @[emailStep];
    __weak typeof(self)weakSelf = self;
    run_in_default_queue(^{
        __weak WLPhoneViewController* phoneStep = [weakSelf stepViewController:@"WLPhoneViewController"];
        __weak WLActivationViewController* verificationStep = [weakSelf stepViewController:@"WLActivationViewController"];
        __weak WLLinkDeviceViewController* linkDeviceStep = [weakSelf stepViewController:@"WLLinkDeviceViewController"];
        __weak WLEmailConfirmationViewController *emailConfirmationStep = [weakSelf stepViewController:@"WLEmailConfirmationViewController"];
        __weak WLSignupStepViewController* verificationSuccessStep = [weakSelf stepViewController:@"WLVerificationSuccessViewController"];
        __weak WLSignupStepViewController* verificationFailureStep = [weakSelf stepViewController:@"WLVerificationFailureViewController"];
        __weak WLSignupStepViewController* linkDeviceSuccessStep = [weakSelf stepViewController:@"WLLinkDeviceSuccessViewController"];
        __weak WLSignupStepViewController* emailConfirmationSuccessStep = [weakSelf stepViewController:@"WLEmailConfirmationSuccessViewController"];
        __weak WLProfileInformationViewController* profileStep = [weakSelf stepViewController:@"WLProfileInformationViewController"];
        
        // final completion block
        
        WLBlock completeSignUp = ^ {
            [UIWindow mainWindow].rootViewController = [[UIStoryboard storyboardNamed:WLMainStoryboard] instantiateInitialViewController];
        };
        
        // profile subflow (will be skipped if is not required)
        
        WLSignupStepCompletionBlock profileStepBlock = ^WLSignupStepViewController *{
            WLUser *user = [WLUser currentUser];
            if (user.name.nonempty && user.picture.medium.nonempty) {
                completeSignUp();
                return nil;
            } else {
                [profileStep setSuccessStatusBlock:^WLSignupStepViewController *{
                    completeSignUp();
                    return nil;
                }];
                return profileStep;
            }
        };
        
        // verification subflow
        
        WLSignupStepCompletionWithSuccessBlock verificationStepBlock = ^WLSignupStepViewController * (WLSignupStepCompletionBlock seccessBlock) {
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
                return verificationStep;
            }];
            return phoneStep;
        };
        
        // device linking subflow
        
        WLSignupStepCompletionBlock linkDeviceBlock = ^WLSignupStepViewController *{
            [linkDeviceStep setSuccessStatusBlock:^WLSignupStepViewController *{
                [linkDeviceSuccessStep setSuccessStatusBlock:^WLSignupStepViewController *{
                    return profileStepBlock();
                }];
                return linkDeviceSuccessStep;
            }];
            return linkDeviceStep;
        };
        
        // second device signup subflow (different for phone and wifi device)
        
        WLSignupStepCompletionBlock secondDeviceBlock = ^WLSignupStepViewController *{
            
            if ([WLTelephony hasPhoneNumber]) {
                return verificationStepBlock(^WLSignupStepViewController *{
                    return linkDeviceBlock();
                });
            } else {
                return linkDeviceBlock();
            }
            return verificationStep;
        };
        
        // first sign up flow
        
        [emailStep setCompletionBlock:^WLSignupStepViewController *{
            return verificationStepBlock(^WLSignupStepViewController *{
                return profileStepBlock();
            });
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
    });
    
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return self.headerView.bounds.size.height;
}

@end
