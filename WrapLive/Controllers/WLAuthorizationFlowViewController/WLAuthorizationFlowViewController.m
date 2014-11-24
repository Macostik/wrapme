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
#import "WLAuthorizationFlow.h"

@interface WLAuthorizationFlowViewController ()

@property (strong, nonatomic) WLAuthorizationFlow* flow;

@end

@implementation WLAuthorizationFlowViewController

- (void)viewDidLoad {
	[super viewDidLoad];
    UINavigationController* navigationController = [self.childViewControllers lastObject];
    self.flow = [[WLAuthorizationFlow alloc] initWithNavigationController:navigationController];
    self.flow.registrationNotCompleted = self.registrationNotCompleted;
    [self.flow start];
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return 151;
}

@end
