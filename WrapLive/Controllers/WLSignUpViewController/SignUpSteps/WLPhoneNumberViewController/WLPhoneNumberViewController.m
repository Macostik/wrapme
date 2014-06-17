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
#import "WLToast.h"
#import "WLHomeViewController.h"
#import "RMPhoneFormat.h"

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

@property (strong, nonatomic) RMPhoneFormat *phoneFormat;

@end

@implementation WLPhoneNumberViewController {
    NSMutableCharacterSet *_phoneChars;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.country = [WLCountry getCurrentCountry];
    _phoneChars = [[NSCharacterSet decimalDigitCharacterSet] mutableCopy];
    [_phoneChars addCharactersInString:@"+*#,"];
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
    self.phoneFormat = [[RMPhoneFormat alloc] initWithDefaultCountry:[self.country.code lowercaseString]];
    if (self.phoneNumberTextField.text.nonempty) {
        NSString *text = self.phoneNumberTextField.text;
        NSString *phone = [self.phoneFormat format:text];
        self.phoneNumberTextField.text = phone;
    }
	[self validateSignUpButton];
}

- (void)setPhoneNumber:(NSString *)phoneNumber {
    _phoneNumber = phoneNumberClearing (phoneNumber);
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
    authorization.formattedPhone = self.phoneNumberTextField.text;
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.phoneNumberTextField) {
        // For some reason, the 'range' parameter isn't always correct when backspacing through a phone number
        // This calculates the proper range from the text field's selection range.
        UITextRange *selRange = textField.selectedTextRange;
        UITextPosition *selStartPos = selRange.start;
        UITextPosition *selEndPos = selRange.end;
        NSInteger start = [textField offsetFromPosition:textField.beginningOfDocument toPosition:selStartPos];
        NSInteger end = [textField offsetFromPosition:textField.beginningOfDocument toPosition:selEndPos];
        NSRange repRange;
        if (start == end) {
            if (string.length == 0) {
                repRange = NSMakeRange(start - 1, 1);
            } else {
                repRange = NSMakeRange(start, end - start);
            }
        } else {
            repRange = NSMakeRange(start, end - start);
        }
        
        // This is what the new text will be after adding/deleting 'string'
        NSString *txt = [textField.text stringByReplacingCharactersInRange:repRange withString:string];
        // This is the newly formatted version of the phone number
        NSString *phone = [_phoneFormat format:txt];
//        BOOL valid = [_phoneFormat isPhoneNumberValid:phone];
//        
//        textField.textColor = valid ? [UIColor blackColor] : [UIColor redColor];
        
        // If these are the same then just let the normal text changing take place
        if ([phone isEqualToString:txt]) {
            return YES;
        } else {
            // The two are different which means the adding/removal of a character had a bigger effect
            // from adding/removing phone number formatting based on the new number of characters in the text field
            // The trick now is to ensure the cursor stays after the same character despite the change in formatting.
            // So first let's count the number of non-formatting characters up to the cursor in the unchanged text.
            int cnt = 0;
            for (NSUInteger i = 0; i < repRange.location + string.length; i++) {
                if ([_phoneChars characterIsMember:[txt characterAtIndex:i]]) {
                    cnt++;
                }
            }
            
            // Now let's find the position, in the newly formatted string, of the same number of non-formatting characters.
            int pos = [phone length];
            int cnt2 = 0;
            for (NSUInteger i = 0; i < [phone length]; i++) {
                if ([_phoneChars characterIsMember:[phone characterAtIndex:i]]) {
                    cnt2++;
                }
                
                if (cnt2 == cnt) {
                    pos = i + 1;
                    break;
                }
            }
            
            // Replace the text with the updated formatting
            textField.text = phone;

            // Make sure the caret is in the right place
            UITextPosition *startPos = [textField positionFromPosition:textField.beginningOfDocument offset:pos];
            UITextRange *textRange = [textField textRangeFromPosition:startPos toPosition:startPos];
            textField.selectedTextRange = textRange;
            return NO;
        }
    } else {
        return YES;
    }
}

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
