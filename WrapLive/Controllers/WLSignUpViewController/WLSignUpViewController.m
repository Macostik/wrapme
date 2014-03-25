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
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *stepDoneViews;
@property (strong, nonatomic) IBOutlet UIView *signUpStepsView;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *stepViews;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIDatePicker * birthdatePicker;
@property (strong, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (strong, nonatomic) IBOutlet UITextField *birthdateTextField;
@property (strong, nonatomic) WLUser * user;
@property (strong, nonatomic) IBOutlet UIButton *selectCountryButton;
@property (strong, nonatomic) IBOutlet UILabel *countryCodeLabel;

@property (strong, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (strong, nonatomic) IBOutlet UITextField *activationTextField;

@property (strong, nonatomic) IBOutlet UIView *inProgressView;
@property (strong, nonatomic) IBOutlet UILabel *inProgressPhoneLabel;
@property (strong, nonatomic) IBOutlet UIView *successfulView;
@property (strong, nonatomic) IBOutlet UILabel *successfulPhoneLabel;
@property (strong, nonatomic) IBOutlet UIView *failedView;
@property (strong, nonatomic) IBOutlet UILabel *failedPhoneLabel;

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
	NSInteger currentStep = index + 1;
	
	for (UILabel* label in self.stepLabels) {
		NSUInteger idx = [self.stepLabels indexOfObject:label];
		label.hidden = idx >= currentStep;
	}
	
	for (UIView* view in self.stepViews) {
		NSUInteger idx = [self.stepViews indexOfObject:view];
		view.hidden = idx < currentStep;
	}
}

- (void)enlargeScrollOffset {
	[self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x + self.scrollView.frame.size.width, self.scrollView.contentOffset.y) animated:YES];
}

- (void)reduceScrollOffset {
	[self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x - self.scrollView.frame.size.width, self.scrollView.contentOffset.y) animated:YES];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	NSUInteger index = [navigationController.viewControllers indexOfObject:viewController];
	[self updateStepLabelsWithIndex:index];
}

@end
