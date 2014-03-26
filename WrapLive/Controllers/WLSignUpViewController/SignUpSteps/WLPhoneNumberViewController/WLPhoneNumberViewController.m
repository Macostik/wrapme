//
//  WLPhoneNumberViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/25/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLPhoneNumberViewController.h"
#import "WLUser.h"
#import "WLAPIManager.h"
#import "NSDate+Formatting.h"
#import "WLActivationViewController.h"
#import "WLCountriesViewController.h"
#import "WLCountry.h"

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
	self.phoneNumberTextField.inputAccessoryView = [self addToolBarWithSelectorsCancel:@selector(phoneNumberTextFieldCancel:) andDone:@selector(phoneNumberTextFieldDone:)];
	self.birthdatePicker = [UIDatePicker new];
	self.birthdatePicker.datePickerMode = UIDatePickerModeDate;
	self.birthdatePicker.maximumDate = [NSDate date];
	self.birthdatePicker.backgroundColor = [UIColor whiteColor];
	self.birthdateTextField.inputAccessoryView = [self addToolBarWithSelectorsCancel:@selector(birthdatePickerCancel:) andDone:@selector(birthdatePickerDone:)];
	self.birthdateTextField.inputView = self.birthdatePicker;
}

- (UIToolbar *) addToolBarWithSelectorsCancel:(SEL)cancel andDone:(SEL)done
{
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                           target:self
                                                                           action:cancel];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                           target:self
                                                                           action:cancel];
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:self
                                                                           action:done];
    toolbar.items = @[item1, item2, item3];
    return toolbar;
}

- (void)birthdatePickerCancel:(id)sender {
	self.birthdateTextField.text = nil;
	[self.birthdateTextField resignFirstResponder];
}

- (void)birthdatePickerDone:(id)sender {
	self.birthdateTextField.text = [self.birthdatePicker.date stringWithFormat:@"MMM' 'dd', 'YYYY'"];
	[self.birthdateTextField resignFirstResponder];
}

- (void)phoneNumberTextFieldCancel:(id)sender {
	self.phoneNumberTextField.text = nil;
	[self.phoneNumberTextField resignFirstResponder];
}

- (void)phoneNumberTextFieldDone:(id)sender {
	[self.phoneNumberTextField resignFirstResponder];
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

- (void)scrollTextFieldToVisible:(UITextField *)textField {
	CGAffineTransform transform;
	if (textField == self.phoneNumberTextField) {
		transform = CGAffineTransformMakeTranslation(0, -40);
	}
	else {
		transform = CGAffineTransformMakeTranslation(0, -140);
	}
	
    [UIView animateWithDuration:0.5 animations:^{
		self.view.transform = transform;
	}];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[self scrollTextFieldToVisible:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[UIView animateWithDuration:0.25 animations:^{
		self.view.transform = CGAffineTransformIdentity;
	}];
}

@end
