//
//  WLPhoneNumberViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/25/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLPhoneNumberViewController.h"
#import "NSDate+Formatting.h"
#import "WLActivationViewController.h"
#import "WLCountriesViewController.h"
#import "WLCountry.h"
#import "WLInputAccessoryView.h"
#import "WLAPIManager.h"
#import "UIColor+CustomColors.h"
#import "UIView+Shorthand.h"
#import "UIButton+Additions.h"
#import "NSDate+Additions.h"
#import "NSString+Additions.h"
#import "UIAlertView+Blocks.h"
#import "WLSession.h"
#import "WLAuthorization.h"
#import "WLTestUserPicker.h"
#import "WLNavigation.h"
#import "NSString+Additions.h"
#import "WLToast.h"
#import "WLHomeViewController.h"

@interface WLPhoneNumberViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@property (weak, nonatomic) IBOutlet UIButton *selectCountryButton;
@property (weak, nonatomic) IBOutlet UILabel *countryCodeLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIView *mainView;

@property (strong, nonatomic) WLCountry *country;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *phoneNumber;

@property (nonatomic, readonly) UIViewController* signUpViewController;

@end

@implementation WLPhoneNumberViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.country = [WLCountry getCurrentCountry];
	self.phoneNumberTextField.inputAccessoryView = [WLInputAccessoryView inputAccessoryViewWithTarget:self cancel:@selector(phoneNumberInputCancel:) done:@selector(phoneNumberInputDone:)];
	self.phoneNumberTextField.text = [WLAuthorization currentAuthorization].phone;
	self.phoneNumber = self.phoneNumberTextField.text;
	self.emailTextField.inputAccessoryView = [WLInputAccessoryView inputAccessoryViewWithTarget:self cancel:@selector(emailInputCancel:) done:@selector(emailInputDone:)];
	self.emailTextField.text = [WLAuthorization currentAuthorization].email;
	self.email = self.emailTextField.text;
	
	if ([WLAPIManager developmentEvironment]) {
		__weak typeof(self)weakSelf = self;
		run_after(0.1, ^{
			UIButton* testUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
			testUserButton.frame = CGRectMake(0, weakSelf.view.height - 88, 320, 44);
			[testUserButton setTitle:@"Test user (for debug only)" forState:UIControlStateNormal];
			[testUserButton setTitleColor:[UIColor WL_orangeColor] forState:UIControlStateNormal];
			[testUserButton addTarget:weakSelf action:@selector(selectTestUser) forControlEvents:UIControlEventTouchUpInside];
			[weakSelf.view addSubview:testUserButton];
		});
	}
}

- (UIViewController *)signUpViewController {
	return self.navigationController.parentViewController;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.view.userInteractionEnabled = YES;
}

- (void)setCountry:(WLCountry *)country {
	_country = country;
	[self.selectCountryButton setTitle:self.country.name forState:UIControlStateNormal];
	self.countryCodeLabel.text = [NSString stringWithFormat:@"+%@", self.country.callingCode];
	[self validateSignUpButton];
}

- (void)setPhoneNumber:(NSString *)phoneNumber {
	_phoneNumber = phoneNumber;
	[self validateSignUpButton];
}

- (void)setEmail:(NSString *)email {
	_email = email;
	[self validateSignUpButton];
}

- (void)validateSignUpButton {
	self.signUpButton.active = self.phoneNumber.nonempty && self.email.nonempty;
}

- (WLAuthorization *)authorization {
	WLAuthorization *authorization = [WLAuthorization new];
	authorization.phone = self.phoneNumber;
	authorization.countryCode = self.country.callingCode;
	authorization.email = self.email;
	return authorization;
}

#pragma mark - Actions

- (IBAction)selectCountry:(id)sender {
	[self.view endEditing:YES];
	__weak typeof(self)weakSelf = self;
	WLCountriesViewController* controller = [[WLCountriesViewController alloc] init];
	[controller setSelectionBlock:^(WLCountry *country) {
		weakSelf.country = country;
	}];
	[self.signUpViewController.navigationController pushViewController:controller animated:YES];
}

- (IBAction)signUp:(id)sender {
	if ([self.email isValidEmail]) {
		__weak typeof(self)weakSelf = self;
		[self confirmAuthorization:[self authorization] success:^(WLAuthorization *authorization) {
			[weakSelf signUpAuthorization:authorization];
		}];
	} else {
		[WLToast showWithMessage:@"Your email isn't correct."];
	}
}

- (void)confirmAuthorization:(WLAuthorization*)authorization success:(void (^)(WLAuthorization *authorization))success {
	NSString* confirmationMessage = [NSString stringWithFormat:@"%@\n%@\nIs this correct?",[authorization fullPhoneNumber], [authorization email]];
	[UIAlertView showWithTitle:@"Confirm your details" message:confirmationMessage buttons:@[@"Edit",@"Yes"] completion:^(NSUInteger index) {
		if (index == 1) {
			success(authorization);
		}
	}];
}

- (void)signUpAuthorization:(WLAuthorization*)authorization {
	__weak typeof(self)weakSelf = self;
	[weakSelf.spinner startAnimating];
	weakSelf.view.userInteractionEnabled = NO;
	[authorization signUp:^(WLAuthorization *authorization) {
		WLActivationViewController *controller = [[WLActivationViewController alloc] initWithAuthorization:authorization];
		[weakSelf.navigationController pushViewController:controller animated:YES];
		[weakSelf.spinner stopAnimating];
	} failure:^(NSError *error) {
		weakSelf.view.userInteractionEnabled = YES;
		[weakSelf.spinner stopAnimating];
		[error show];
	}];
}

- (void)signInAuthorization:(WLAuthorization*)authorization {
	__weak typeof(self)weakSelf = self;
	[weakSelf.spinner startAnimating];
	weakSelf.view.userInteractionEnabled = NO;
	[authorization signIn:^(WLUser *user) {
		weakSelf.view.userInteractionEnabled = YES;
		[weakSelf.spinner stopAnimating];
        [WLHomeViewController instantiateAndMakeRootViewControllerAnimated:NO];
	} failure:^(NSError *error) {
		weakSelf.view.userInteractionEnabled = YES;
		[weakSelf.spinner stopAnimating];
		[error show];
	}];
}

- (void)phoneNumberInputCancel:(id)sender {
	[self.phoneNumberTextField resignFirstResponder];
}

- (void)phoneNumberInputDone:(id)sender {
	[self.phoneNumberTextField resignFirstResponder];
	[self.emailTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.2f];
}

- (void)emailInputCancel:(id)sender {
	[self.emailTextField resignFirstResponder];
}

- (void)emailInputDone:(id)sender {
	[self.emailTextField resignFirstResponder];
}

- (IBAction)phoneNumberChanged:(UITextField *)sender {
	self.phoneNumber = sender.text;
}

- (IBAction)emailChanged:(UITextField *)sender {
	self.email = sender.text;
}


- (void)selectTestUser {
	__weak typeof(self)weakSelf = self;
	[WLTestUserPicker showInView:self.view selection:^(WLAuthorization *authorization) {
		[weakSelf confirmAuthorization:authorization success:^(WLAuthorization *authorization) {
			if (authorization.password.nonempty) {
				[weakSelf signInAuthorization:authorization];
			} else {
				[weakSelf signUpAuthorization:authorization];
			}
		}];
	}];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	CGFloat translation = textField.superview.y - 0.5 * (self.view.height - 260 - textField.superview.height);
	CGAffineTransform transform = CGAffineTransformMakeTranslation(0, -translation);
	__weak typeof(self)weakSelf = self;
	[UIView animateWithDuration:0.5 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		weakSelf.mainView.transform = transform;
	} completion:^(BOOL finished) {}];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	if (self.phoneNumberTextField.isFirstResponder || self.emailTextField.isFirstResponder) {
		[self.view endEditing:YES];
		return NO;
	}
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (textField == self.phoneNumberTextField) {
		self.phoneNumber = self.phoneNumberTextField.text;
	} else {
		self.email = self.emailTextField.text;
	}
	__weak typeof(self)weakSelf = self;
	[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		weakSelf.mainView.transform = CGAffineTransformIdentity;
	} completion:^(BOOL finished) {}];
}

@end
