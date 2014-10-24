//
//  WLSignUpViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLSignUpViewController.h"
#import "WLAPIManager.h"
#import "WLUser.h"
#import "NSDate+Formatting.h"
#import "WLCountriesViewController.h"
#import "WLCountry.h"
#import "WLProfileInformationViewController.h"
#import "WLPhoneNumberViewController.h"
#import "UIColor+CustomColors.h"
#import "WLNavigation.h"

@interface WLSignUpViewController ()

@property (strong, nonatomic) IBOutlet UIView *signUpStepsView;

@end

@implementation WLSignUpViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	if (self.registrationNotCompleted) {
        UINavigationController* navigationController = [self.childViewControllers lastObject];
        navigationController.viewControllers = @[[WLProfileInformationViewController instantiate:[UIStoryboard storyboardNamed:WLSignUpStoryboard]]];
	}
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return 151;
}

@end
