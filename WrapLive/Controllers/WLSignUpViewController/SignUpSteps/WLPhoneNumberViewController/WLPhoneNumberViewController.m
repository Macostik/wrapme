//
//  WLPhoneNumberViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/25/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLPhoneNumberViewController.h"
#import "WLUser.h"
#import "NSDate+Formatting.h"
#import "WLActivationViewController.h"
#import "WLCountriesViewController.h"
#import "WLCountry.h"
#import "WLInputAccessoryView.h"
#import "WLAPIManager.h"
#import "UIColor+CustomColors.h"
#import "UIView+Shorthand.h"
#import "UIButton+Additions.h"

@interface WLPhoneNumberViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIButton *signUpButton;
@property (strong, nonatomic) UIDatePicker * birthdatePicker;
@property (strong, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (strong, nonatomic) IBOutlet UITextField *birthdateTextField;
@property (strong, nonatomic) WLUser * user;
@property (strong, nonatomic) WLCountry * country;
@property (strong, nonatomic) IBOutlet UIButton *selectCountryButton;
@property (strong, nonatomic) IBOutlet UILabel *countryCodeLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (nonatomic, readonly) UIViewController* signUpViewController;

@end

@implementation WLPhoneNumberViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setupPicker];
	self.country = [WLCountry getCurrentCountry];
	[self fillCountryFields];
	[self validateSignUpButton];
	self.birthdateTextField.text = [self.birthdatePicker.date stringWithFormat:@"MMM' 'dd', 'YYYY'"];
}

- (UIViewController *)signUpViewController {
	return self.navigationController.parentViewController;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.view.userInteractionEnabled = YES;
}

- (void)setupPicker {
	[WLInputAccessoryView inputAccessoryViewWithResponder:self.phoneNumberTextField];
	self.birthdatePicker = [UIDatePicker new];
	self.birthdatePicker.datePickerMode = UIDatePickerModeDate;
	self.birthdatePicker.maximumDate = [NSDate date];
	self.birthdatePicker.backgroundColor = [UIColor whiteColor];
	self.birthdatePicker.date = [NSDate defaultBirtday];
	self.birthdateTextField.inputAccessoryView = [WLInputAccessoryView inputAccessoryViewWithTarget:self cancel:@selector(birthdatePickerCancel:) done:@selector(birthdatePickerDone:)];
	self.birthdateTextField.inputView = self.birthdatePicker;
}

- (void)birthdatePickerCancel:(id)sender {
	self.birthdateTextField.text = nil;
	[self.birthdateTextField resignFirstResponder];
	[self validateSignUpButton];
}

- (void)birthdatePickerDone:(id)sender {
	self.birthdateTextField.text = [self.birthdatePicker.date stringWithFormat:@"MMM' 'dd', 'YYYY'"];
	[self.birthdateTextField resignFirstResponder];
	[self validateSignUpButton];
}

- (void)fillCountryFields {
	[self.selectCountryButton setTitle:self.country.name forState:UIControlStateNormal];
	self.countryCodeLabel.text = [NSString stringWithFormat:@"+%@", self.country.callingCode];
}

- (IBAction)selectCountry:(id)sender {
	[self.view endEditing:YES];
	__weak typeof(self)weakSelf = self;
	WLCountriesViewController* controller = [[WLCountriesViewController alloc] init];
	[controller setSelectionBlock:^(WLCountry *country) {
		weakSelf.country = country;
		[weakSelf fillCountryFields];
	}];
	[self.signUpViewController.navigationController pushViewController:controller animated:YES];
}

- (IBAction)signUp:(id)sender {
	[self.spinner startAnimating];
	self.view.userInteractionEnabled = NO;
	self.user = [self prepareForRequest];
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] signUp:self.user success:^(id object) {
		WLActivationViewController *controller = [[WLActivationViewController alloc] initWithUser:weakSelf.user];
		[weakSelf.navigationController pushViewController:controller animated:YES];
		[weakSelf.spinner stopAnimating];
	} failure:^(NSError *error) {
		weakSelf.view.userInteractionEnabled = YES;
		[weakSelf.spinner stopAnimating];
		[error show];
	}];
}

- (IBAction)phoneNumberChanged:(UITextField *)sender {
	[self validateSignUpButton];
}

- (void)validateSignUpButton {
	self.signUpButton.active = (self.phoneNumberTextField.text.length > 0 ? YES : NO) && (self.birthdateTextField.text.length > 0 ? YES : NO);
}

- (WLUser *)prepareForRequest {
	self.user = [WLUser new];
	self.user.phoneNumber = self.phoneNumberTextField.text;
	self.user.countryCallingCode = self.country.callingCode;
	self.user.birthdate = self.birthdatePicker.date;
	return self.user;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	CGFloat translation = textField.superview.y - 0.5 * (self.view.height - 260 - textField.superview.height);
	CGAffineTransform transform = CGAffineTransformMakeTranslation(0, -translation);
	[UIView animateWithDuration:0.5 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.mainView.transform = transform;
	} completion:^(BOOL finished) {}];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	if (self.phoneNumberTextField.isFirstResponder || self.birthdateTextField.isFirstResponder) {
		[self.view endEditing:YES];
		return NO;
	}
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.mainView.transform = CGAffineTransformIdentity;
	} completion:^(BOOL finished) {}];
}

@end
