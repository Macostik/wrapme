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

@interface WLPhoneNumberViewController ()

@property (strong, nonatomic) UIDatePicker * birthdatePicker;
@property (strong, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (strong, nonatomic) IBOutlet UITextField *birthdateTextField;
@property (strong, nonatomic) WLUser * user;
@property (strong, nonatomic) IBOutlet UIButton *selectCountryButton;
@property (strong, nonatomic) IBOutlet UILabel *countryCodeLabel;

@end

@implementation WLPhoneNumberViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setupPicker];
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

- (IBAction)selectCountry:(id)sender {
	[WLCountriesViewController show:^(WLCountry *country) {
		[self.selectCountryButton setTitle:country.name forState:UIControlStateNormal];
		self.countryCodeLabel.text = country.callingCode;
	}];
}

- (IBAction)signUp:(id)sender {
	[[WLAPIManager instance] signUp:[self prepareForRequest] success:^(id object) {
		WLActivationViewController * controller = [WLActivationViewController new];
		controller.phoneNumberLabel.text = [NSString stringWithFormat:@"%@ %@", self.countryCodeLabel.text, self.phoneNumberTextField.text];
		controller.currentUser = self.user;
		[self.navigationController pushViewController:controller animated:YES];
	} failure:^(NSError *error) {
		
	}];
}

- (WLUser *)prepareForRequest {
	self.user = [WLUser new];
	self.user.phoneNumber = self.phoneNumberTextField.text;
	self.user.countryCallingCode = self.countryCodeLabel.text;
	self.user.birthdate = self.birthdatePicker.date;
	return self.user;
}

//- (void)scrollTextFieldToVisible:(UITextField *)textField
//{
//    [self.scrollView setContentOffset:CGPointZero animated:YES];
//    
//    if ([textField isFirstResponder])
//    {
//		//		float toolBarHeight = textField.inputAccessoryView ? 44 : 0;
//        CGPoint scrollPoint = CGPointMake(self.scrollView.contentOffset.x, textField.frame.origin.y - 50);
//        [self.scrollView setContentOffset:scrollPoint animated:YES];
//    }
//}
//
//#pragma mark - UITextFieldDelegate
//
//- (void)textFieldDidBeginEditing:(UITextField *)textField {
//	
//	[self scrollTextFieldToVisible:textField];
//}
//
//- (void)textFieldDidEndEditing:(UITextField *)textField {
//	CGPoint scrollPoint = CGPointMake(self.scrollView.contentOffset.x, 0.0);
//	[self.scrollView setContentOffset:scrollPoint animated:NO];
//}

@end
