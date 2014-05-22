//
//  WLViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWelcomeViewController.h"
#import "WLSession.h"
#import "WLAPIManager.h"
#import "UIStoryboard+Additions.h"
#import "WLAuthorization.h"
#import "WLSignUpViewController.h"
#import "NSString+Additions.h"
#import "WLUser.h"

@interface WLWelcomeViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;

@end

@implementation WLWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	self.continueButton.hidden = YES;
	if ([[WLAuthorization currentAuthorization] canAuthorize]) {
		__weak typeof(self)weakSelf = self;
		[[WLAPIManager instance] signIn:[WLAuthorization currentAuthorization] success:^(WLUser* user) {
			if (user.name.nonempty) {
				[weakSelf presentHomeViewController];
			} else {
				[weakSelf continueSignUp];
			}
		} failure:^(NSError *error) {
			if ([error isNetworkError]) {
				[weakSelf presentHomeViewController];
			} else {
				[weakSelf showContinueButton];
			}
		}];
	} else {
		[self showContinueButton];
	}
}

- (void)showContinueButton {
	self.continueButton.transform = CGAffineTransformMakeTranslation(0, self.continueButton.frame.size.height);
	self.continueButton.hidden = NO;
	__weak typeof(self)weakSelf = self;
	[UIView animateWithDuration:0.25f animations:^{
		weakSelf.continueButton.transform = CGAffineTransformIdentity;
	}];
	[self.spinner removeFromSuperview];
}

- (void)presentHomeViewController {
	[self.navigationController setViewControllers:@[[self.storyboard homeViewController]]];
}

- (void)continueSignUp {
	WLSignUpViewController * controller = [self.storyboard signUpViewController];
	controller.registrationNotCompleted = YES;
	[self.navigationController setViewControllers:@[controller]];
}

@end
