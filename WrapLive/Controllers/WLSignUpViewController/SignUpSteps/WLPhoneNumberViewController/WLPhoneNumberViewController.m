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

@interface WLPhoneNumberViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIButton *signUpButton;
@property (strong, nonatomic) UIDatePicker * birthdatePicker;
@property (strong, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (strong, nonatomic) IBOutlet UITextField *birthdateTextField;
@property (strong, nonatomic) WLUser * user;
@property (strong, nonatomic) WLCountry * country;
@property (strong, nonatomic) IBOutlet UIButton *selectCountryButton;
@property (strong, nonatomic) IBOutlet UILabel *countryCodeLabel;

@end

@implementation WLPhoneNumberViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setupPicker];
	self.country = [WLCountry getCurrentCountry];
	[self fillCountryFields];
}

- (void)setupPicker {
	[WLInputAccessoryView inputAccessoryViewWithResponder:self.phoneNumberTextField];
	self.birthdatePicker = [UIDatePicker new];
	self.birthdatePicker.datePickerMode = UIDatePickerModeDate;
	self.birthdatePicker.maximumDate = [NSDate date];
	self.birthdatePicker.backgroundColor = [UIColor whiteColor];
	self.birthdateTextField.inputAccessoryView = [WLInputAccessoryView inputAccessoryViewWithTarget:self cancel:@selector(birthdatePickerCancel:) done:@selector(birthdatePickerDone:)];
	self.birthdateTextField.inputView = self.birthdatePicker;
}

- (void)birthdatePickerCancel:(id)sender {
	self.birthdateTextField.text = nil;
	[self.birthdateTextField resignFirstResponder];
}

- (void)birthdatePickerDone:(id)sender {
	self.birthdateTextField.text = [self.birthdatePicker.date stringWithFormat:@"MMM' 'dd', 'YYYY'"];
	[self.birthdateTextField resignFirstResponder];
}

- (void)fillCountryFields {
	[self.selectCountryButton setTitle:self.country.name forState:UIControlStateNormal];
	self.countryCodeLabel.text = [NSString stringWithFormat:@"+%@", self.country.callingCode];
}

- (IBAction)selectCountry:(id)sender {
	[WLCountriesViewController show:^(WLCountry *country) {
		self.country = country;
		[self fillCountryFields];
	}];
}

- (IBAction)signUp:(id)sender {
	self.user = [self prepareForRequest];
	WLActivationViewController *controller = [[WLActivationViewController alloc] initWithUser:self.user];
	[self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)phoneNumberChanged:(UITextField *)sender {
	self.signUpButton.enabled = self.phoneNumberTextField.text.length > 0 ? YES : NO;
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
	CGFloat translation = textField.frame.origin.y - 0.5 * (self.view.frame.size.height - 260 - textField.frame.size.height);
	CGAffineTransform transform = CGAffineTransformMakeTranslation(0, -translation);
	[UIView animateWithDuration:0.5 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.view.transform = transform;
	} completion:^(BOOL finished) {}];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.view.transform = CGAffineTransformIdentity;
	} completion:^(BOOL finished) {}];
}

@end
