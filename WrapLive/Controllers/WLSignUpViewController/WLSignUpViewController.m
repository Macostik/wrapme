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

@interface WLSignUpViewController () <UIScrollViewDelegate, UITextFieldDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *stepLines;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *completedStepViews;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *incompletedStepViews;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *currentStepViews;
@property (strong, nonatomic) IBOutlet UIView *signUpStepsView;

@end

@implementation WLSignUpViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	for (UIView* view in self.incompletedStepViews) {
		view.layer.borderWidth = 1;
		view.layer.borderColor = [UIColor WL_grayColor].CGColor;
	}
	
	for (UIView* view in self.currentStepViews) {
		view.layer.borderWidth = 1;
		view.layer.borderColor = [UIColor WL_orangeColor].CGColor;
	}
	
	if (self.registrationNotCompleted) {
		WLProfileInformationViewController * controller = [[WLProfileInformationViewController alloc] init];
		[self createNavController:controller];
		[self updateStepLabelsWithIndex:2];
	}
	else {
		WLPhoneNumberViewController * controller = [[WLPhoneNumberViewController alloc] init];
		[self createNavController:controller];
	}
}

- (void)createNavController:(UIViewController *)controller {
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
	navController.view.frame = self.signUpStepsView.bounds;
	navController.navigationBarHidden = YES;
	navController.delegate = self;
	[navController willMoveToParentViewController:self];
	[self addChildViewController:navController];
	[self.signUpStepsView addSubview:navController.view];
}

- (void)updateStepLabelsWithIndex:(int)index {
	
	[self setHiddenViews:self.incompletedStepViews byBlock:^BOOL(NSUInteger idx) {
		return idx <= index;
	}];
	
	[self setHiddenViews:self.completedStepViews byBlock:^BOOL(NSUInteger idx) {
		return idx >= index;
	}];
	
	[self setHiddenViews:self.currentStepViews byBlock:^BOOL(NSUInteger idx) {
		return idx != index;
	}];
	
	[self setHiddenViews:self.stepLines byBlock:^BOOL(NSUInteger idx) {
		return idx >= index;
	}];
}

- (void)setHiddenViews:(NSArray*)views byBlock:(BOOL (^)(NSUInteger idx))block {
	for (UIView* view in views) {
		view.hidden = block([views indexOfObject:view]);
	}
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	NSUInteger index = [navigationController.viewControllers indexOfObject:viewController];
	if (!self.registrationNotCompleted) {
		[self updateStepLabelsWithIndex:index];
	}
}

@end
