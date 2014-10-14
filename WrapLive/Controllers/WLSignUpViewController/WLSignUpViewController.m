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

@interface WLSignUpViewController ()

@property (strong, nonatomic) IBOutlet UIView *signUpStepsView;

@end

@implementation WLSignUpViewController

- (void)viewDidLoad {
	[super viewDidLoad];
    
	if (self.registrationNotCompleted) {
		[self createNavController:[[WLProfileInformationViewController alloc] init]];
	} else {
		[self createNavController:[[WLPhoneNumberViewController alloc] init]];
	}
}

- (void)createNavController:(UIViewController *)controller {
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
	navController.view.frame = self.signUpStepsView.bounds;
	navController.navigationBarHidden = YES;
	[navController willMoveToParentViewController:self];
	[self addChildViewController:navController];
	[self.signUpStepsView addSubview:navController.view];
}

@end
