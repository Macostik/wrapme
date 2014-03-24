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

@interface WLSignUpViewController () <UIScrollViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *stepLabels;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *stepDoneViews;
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
	self.scrollView.contentSize = CGSizeMake(CGRectGetMaxX([[self.stepViews lastObject] frame]), self.scrollView.frame.size.height);
	[self updateStepLabels];
	[self setupPicker];
	[self.selectCountryButton setTitle:@"Unated State" forState:UIControlStateNormal];
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

- (void)activationCancel:(id)sender {
	self.activationTextField.text = nil;
	[self.activationTextField resignFirstResponder];
}

- (void)activationDone:(id)sender {
	
	[self.activationTextField resignFirstResponder];
}
#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self updateStepLabels];
	
}

- (void)updateStepLabels {
	NSInteger currentStep = roundf(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
	
	for (UILabel* label in self.stepLabels) {
		NSUInteger idx = [self.stepLabels indexOfObject:label];
		label.hidden = idx >= currentStep;
	}
	
	for (UIView* view in self.stepViews) {
		NSUInteger idx = [self.stepViews indexOfObject:view];
		view.hidden = idx < currentStep;
	}
}

#pragma mark - User Actions

- (IBAction)selectCountry:(id)sender {
	[WLCountriesViewController show:^(WLCountry *country) {
		[self.selectCountryButton setTitle:country.name forState:UIControlStateNormal];
		self.countryCodeLabel.text = country.callingCode;
	}];
}


- (IBAction)editNumber:(id)sender {
	[self reduceScrollOffset];
}

- (IBAction)tryAgain:(id)sender {
	self.activationTextField.text = nil;
	[self reduceScrollOffset];
}

- (IBAction)signUp:(id)sender {
//	[[WLAPIManager instance] signUp:[self prepareForRequest] success:^(id object) {
//		[self activation];
//	} failure:^(NSError *error) {
//		
//	}];
	[self activation];
}

- (IBAction)nextStep:(id)sender {
	[self enlargeScrollOffset];
	self.user.activationCode = self.activationTextField.text;
//TODO: verify request 
	[[WLAPIManager instance] activate:self.user success:^(id object) {
		self.inProgressView.hidden = YES;
		self.successfulView.hidden = NO;
		self.successfulPhoneLabel.text = self.phoneNumberTextField.text;
	} failure:^(NSError *error) {
		self.inProgressView.hidden = YES;
		self.failedView.hidden = NO;
		self.failedPhoneLabel.text = self.phoneNumberTextField.text;
	}];
}

- (WLUser *)prepareForRequest {
	self.user = [WLUser new];
	self.user.phoneNumber = self.phoneNumberTextField.text;
	self.user.countryCallingCode = self.countryCodeLabel.text;
	self.user.birthdate = self.birthdatePicker.date;
	return self.user;
}

- (void)activation {
	[self enlargeScrollOffset];
	self.phoneNumberLabel.text = [NSString stringWithFormat:@"%@ %@", self.countryCodeLabel.text, self.phoneNumberTextField.text];
	self.activationTextField.inputAccessoryView = [self addToolBarWithSelectorsCancel:@selector(activationCancel:) andDone:@selector(activationDone:)];
	
}

- (void)enlargeScrollOffset {
	[self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x + self.scrollView.frame.size.width, self.scrollView.contentOffset.y) animated:YES];
}

- (void)reduceScrollOffset {
	[self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x - self.scrollView.frame.size.width, self.scrollView.contentOffset.y) animated:YES];
}

- (void)scrollTextFieldToVisible:(UITextField *)textField
{
    [self.scrollView setContentOffset:CGPointZero animated:YES];
    
    if ([textField isFirstResponder])
    {
//		float toolBarHeight = textField.inputAccessoryView ? 44 : 0;
        CGPoint scrollPoint = CGPointMake(self.scrollView.contentOffset.x, textField.frame.origin.y - 50);
        [self.scrollView setContentOffset:scrollPoint animated:YES];
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
	[self scrollTextFieldToVisible:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	CGPoint scrollPoint = CGPointMake(self.scrollView.contentOffset.x, 0.0);
	[self.scrollView setContentOffset:scrollPoint animated:NO];
}

@end
