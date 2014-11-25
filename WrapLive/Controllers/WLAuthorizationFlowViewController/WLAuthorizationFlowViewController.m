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
        self.flowNavigationController.viewControllers = @[[WLProfileInformationViewController instantiate:[UIStoryboard storyboardNamed:WLSignUpStoryboard]]];
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
        /*if (whoIs.found) {
            
        } else*/ {
            WLPhoneViewController* phoneViewController = [WLPhoneViewController instantiate:weakSelf.storyboard];
            [phoneViewController setEmail:email];
            [weakSelf.flowNavigationController pushViewController:phoneViewController animated:YES];
        }
    } failure:^(NSError *error) {
        
    }];
}

@end
