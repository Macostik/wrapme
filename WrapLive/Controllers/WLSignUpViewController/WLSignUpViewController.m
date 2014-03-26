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

#import "WLPhoneNumberViewController.h"

@interface WLSignUpViewController () <UIScrollViewDelegate, UITextFieldDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *stepLabels;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *stepViews;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *stepDoneViews;
@property (strong, nonatomic) IBOutlet UIView *signUpStepsView;

@end

@implementation WLSignUpViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	WLPhoneNumberViewController * controller = [[WLPhoneNumberViewController alloc] init];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
	navController.view.frame = self.signUpStepsView.bounds;
	navController.navigationBarHidden = YES;
	navController.delegate = self;
	[navController willMoveToParentViewController:self];
	[self addChildViewController:navController];
	[self.signUpStepsView addSubview:navController.view];
}

- (void)updateStepLabelsWithIndex:(int)index {
	
	for (UILabel* label in self.stepLabels) {
		NSUInteger idx = [self.stepLabels indexOfObject:label];
		label.hidden = idx > index;
	}
	
	for (UIView* view in self.stepViews) {
		NSUInteger idx = [self.stepViews indexOfObject:view];
		view.hidden = idx <= index;
	}
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	NSUInteger index = [navigationController.viewControllers indexOfObject:viewController];
	[self updateStepLabelsWithIndex:index];
}

@end
