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
#import "NSDate+Additions.h"
#import "NSString+Additions.h"
#import "UIAlertView+Blocks.h"
#import "WLSession.h"

@interface WLPhoneNumberViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) UIDatePicker *birthdatePicker;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (weak, nonatomic) IBOutlet UITextField *birthdateTextField;
@property (weak, nonatomic) IBOutlet UIButton *selectCountryButton;
@property (weak, nonatomic) IBOutlet UILabel *countryCodeLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIView *mainView;

@property (strong, nonatomic) WLCountry *country;
@property (strong, nonatomic) NSDate *birthdate;
@property (strong, nonatomic) NSString *phoneNumber;

@property (nonatomic, readonly) UIViewController* signUpViewController;

@end

@implementation WLPhoneNumberViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.country = [WLCountry getCurrentCountry];
	self.phoneNumberTextField.inputAccessoryView = [WLInputAccessoryView inputAccessoryViewWithTarget:self cancel:@selector(phoneNumberInputCancel:) done:@selector(phoneNumberInputDone:)];
	self.phoneNumberTextField.text = [WLSession user].phoneNumber;
	
	if ([WLSession birthdate].nonempty) {
		self.birthdate = [[WLSession birthdate] GMTDate];
		self.birthdatePicker.date = self.birthdate;
	} else {
		self.birthdate = self.birthdatePicker.date;
	}
}

- (UIViewController *)signUpViewController {
	return self.navigationController.parentViewController;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.view.userInteractionEnabled = YES;
}

- (UIDatePicker *)birthdatePicker {
	if (!_birthdatePicker) {
		UIDatePicker *birthdatePicker = [UIDatePicker new];
		birthdatePicker.datePickerMode = UIDatePickerModeDate;
		birthdatePicker.maximumDate = [NSDate date];
		birthdatePicker.backgroundColor = [UIColor whiteColor];
		birthdatePicker.date = [NSDate defaultBirtday];
		birthdatePicker.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
		self.birthdateTextField.inputAccessoryView = [WLInputAccessoryView inputAccessoryViewWithTarget:self cancel:@selector(birthdatePickerCancel:) done:@selector(birthdatePickerDone:)];
		self.birthdateTextField.inputView = birthdatePicker;
		_birthdatePicker = birthdatePicker;
	}
	return _birthdatePicker;
}

- (void)setBirthdate:(NSDate *)birthdate {
	_birthdate = birthdate;
	self.birthdateTextField.text = [birthdate GMTStringWithFormat:@"MMM' 'dd', 'YYYY'"];
	[self validateSignUpButton];
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

- (void)validateSignUpButton {
	self.signUpButton.active = self.phoneNumber.nonempty && [self.birthdate compare:[NSDate defaultBirtday]] != NSOrderedSame;
}

- (WLUser *)prepareForRequest {
	WLUser *user = [WLUser new];
	user.phoneNumber = self.phoneNumber;
	user.countryCallingCode = self.country.callingCode;
	user.birthdate = self.birthdate;
	return user;
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
	__weak typeof(self)weakSelf = self;
	
	WLUser* user = [self prepareForRequest];
	
	NSString* phoneNumber = [NSString stringWithFormat:@"+%@ %@", user.countryCallingCode, user.phoneNumber];
	
	NSString* confirmationMessage = [NSString stringWithFormat:@"%@\n%@\nIs the information above correct?",phoneNumber,[user.birthdate GMTStringWithFormat:@"MMM dd, yyyy"]];
	
	[UIAlertView showWithTitle:@"Confirmation" message:confirmationMessage buttons:@[@"Edit",@"Yes"] completion:^(NSUInteger index) {
		if (index == 1) {
			[weakSelf.spinner startAnimating];
			weakSelf.view.userInteractionEnabled = NO;
			[[WLAPIManager instance] signUp:user
									success:^(id object) {
										WLActivationViewController *controller = [[WLActivationViewController alloc] initWithUser:object];
										[weakSelf.navigationController pushViewController:controller animated:YES];
										[weakSelf.spinner stopAnimating];
									} failure:^(NSError *error) {
										weakSelf.view.userInteractionEnabled = YES;
										[weakSelf.spinner stopAnimating];
										[error show];
									}];
		}
	}];
}

- (void)phoneNumberInputCancel:(id)sender {
	[self.phoneNumberTextField resignFirstResponder];
}

- (void)phoneNumberInputDone:(id)sender {
	[self.phoneNumberTextField resignFirstResponder];
	[self.birthdateTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.2f];
}

- (void)birthdatePickerCancel:(id)sender {
	[self.birthdateTextField resignFirstResponder];
}

- (void)birthdatePickerDone:(id)sender {
	self.birthdate = self.birthdatePicker.date;
	[self.birthdateTextField resignFirstResponder];
}

- (IBAction)phoneNumberChanged:(UITextField *)sender {
	self.phoneNumber = sender.text;
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
	if (self.phoneNumberTextField.isFirstResponder || self.birthdateTextField.isFirstResponder) {
		[self.view endEditing:YES];
		return NO;
	}
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	self.phoneNumber = self.phoneNumberTextField.text;
	__weak typeof(self)weakSelf = self;
	[UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		weakSelf.mainView.transform = CGAffineTransformIdentity;
	} completion:^(BOOL finished) {}];
}

@end
