//
//  WLSignUpViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAuthorizationFlowViewController.h"
#import "WLAPIManager.h"
#import "WLUser.h"
#import "NSDate+Formatting.h"
#import "WLCountriesViewController.h"
#import "WLCountry.h"
#import "WLProfileInformationViewController.h"
#import "WLPhoneViewController.h"
#import "UIColor+CustomColors.h"
#import "WLNavigation.h"
#import "WLAuthorizationRequest.h"
#import "WLAuthorizationSceneViewController.h"
#import "WLEmailViewController.h"
#import "WLPhoneViewController.h"
#import "WLEmailConfirmationViewController.h"
#import "WLLinkDeviceViewController.h"
#import "WLTelephony.h"

@interface WLAuthorizationFlowViewController () <UINavigationControllerDelegate, WLEmailViewControllerDelegate>

@property (weak, nonatomic) UINavigationController* flowNavigationController;
@property (weak, nonatomic) IBOutlet UIView *headerView;

@end

@implementation WLAuthorizationFlowViewController

- (void)viewDidLoad {
	[super viewDidLoad];
    self.flowNavigationController = [self.childViewControllers lastObject];
    self.flowNavigationController.delegate = self;
    if (self.registrationNotCompleted) {
        self.flowNavigationController.viewControllers = @[[WLProfileInformationViewController instantiate:self.storyboard]];
    }
    
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return self.headerView.bounds.size.height;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(WLAuthorizationSceneViewController *)viewController animated:(BOOL)animated {
    viewController.delegate = self;
}

#pragma mark - WLEmailViewControllerDelegate

- (void)emailViewController:(WLEmailViewController *)controller didFinishWithEmail:(NSString *)email {
    WLWhoIsRequest* request = [WLWhoIsRequest request];
    request.email = email;
    __weak typeof(self)weakSelf = self;
    [request send:^(WLWhoIs* whoIs) {
        WLAuthorizationSceneViewController* sceneViewController = nil;
        if (whoIs.found && !whoIs.requiresVerification) {
            if (whoIs.confirmed) {
                if ([WLTelephony hasPhoneNumber]) {
                    sceneViewController = [WLPhoneViewController instantiate:weakSelf.storyboard];
                } else {
                    sceneViewController = [WLLinkDeviceViewController instantiate:weakSelf.storyboard];
                }
            } else {
                sceneViewController = [WLEmailConfirmationViewController instantiate:weakSelf.storyboard];
            }
        } else {
            sceneViewController = [WLPhoneViewController instantiate:weakSelf.storyboard];
        }
        [weakSelf.flowNavigationController pushViewController:sceneViewController animated:YES];
    } failure:^(NSError *error) {
        
    }];
}

@end
