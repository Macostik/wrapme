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

@interface WLSignUpViewController () <UIScrollViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *stepLabels;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *stepDoneViews;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *stepViews;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIDatePicker * birthdatePicker;
@property (strong, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (strong, nonatomic) IBOutlet UITextField *birthdateTextField;

@end

@implementation WLSignUpViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.scrollView.contentSize = CGSizeMake(CGRectGetMaxX([[self.stepViews lastObject] frame]), self.scrollView.frame.size.height);
	[self updateStepLabels];
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
	[self.birthdateTextField resignFirstResponder];
}

- (void)birthdatePickerDone:(id)sender {
	self.birthdateTextField.text = [self createDateString:self.birthdatePicker.date];
	[self.birthdateTextField resignFirstResponder];
}

- (NSString *)createDateString:(NSDate *)date {
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"MMM' 'dd', 'YYYY'"];
	return [formatter stringFromDate:date];
}

- (void)phoneNumberTextFieldCancel:(id)sender {
	self.phoneNumberTextField.text = nil;
	[self.phoneNumberTextField resignFirstResponder];
}

- (void)phoneNumberTextFieldDone:(id)sender {
	
	[self.phoneNumberTextField resignFirstResponder];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self updateStepLabels];
	
}

- (void)updateStepLabels {
	NSInteger currentStep = roundf(self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
	
	[self.stepLabels enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(UILabel* label, NSUInteger idx, BOOL *stop) {
		label.hidden = idx >= currentStep;
	}];
	
	[self.stepViews enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(UIView* view, NSUInteger idx, BOOL *stop) {
		view.hidden = idx < currentStep;
	}];
}

#pragma mark - User Actions

- (IBAction)editNumber:(id)sender {
	[self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x - self.scrollView.frame.size.width, self.scrollView.contentOffset.y) animated:YES];
}

- (IBAction)nextStep:(id)sender {
	[self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x + self.scrollView.frame.size.width, self.scrollView.contentOffset.y) animated:YES];
}

- (void)prepareForRequest {
	WLUser * user = [WLUser new];
	user.phoneNumber = self.phoneNumberTextField.text;
	user.countryCallingCode = @"";
	user.birthdate = self.birthdatePicker.date;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 290, 0);
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	self.scrollView.contentInset = UIEdgeInsetsZero;
}


@end
