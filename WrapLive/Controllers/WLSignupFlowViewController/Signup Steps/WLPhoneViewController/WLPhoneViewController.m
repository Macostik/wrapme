//
//  WLPhoneNumberViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/25/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLPhoneViewController.h"
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
#import "NSObject+NibAdditions.h"
#import "WLSession.h"
#import "WLAuthorization.h"
#import "WLNavigation.h"
#import "WLToast.h"
#import "WLHomeViewController.h"
#import "WLKeyboard.h"
#import "WLAuthorizationRequest.h"
#import "WLButton.h"
#import "WLPhoneValidation.h"
#import "RMPhoneFormat.h"
#import "WLConfirmView.h"

@interface WLPhoneViewController () <UITextFieldDelegate, WLKeyboardBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;

@property (weak, nonatomic) IBOutlet UIButton *selectCountryButton;
@property (weak, nonatomic) IBOutlet UILabel *countryCodeLabel;

@property (strong, nonatomic) WLCountry *country;

@property (strong, nonatomic) IBOutlet WLPhoneValidation *validation;

@end

@implementation WLPhoneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.country = [WLCountry getCurrentCountry];
    
	self.phoneNumberTextField.text = [WLAuthorization currentAuthorization].phone;
}

- (void)setCountry:(WLCountry *)country {
	_country = country;
    [WLAuthorization currentAuthorization].countryCode = country.callingCode;
	[self.selectCountryButton setTitle:country.name forState:UIControlStateNormal];
	self.countryCodeLabel.text = [NSString stringWithFormat:@"+%@", country.callingCode];
    self.validation.format = [[RMPhoneFormat alloc] initWithDefaultCountry:[country.code lowercaseString]];
}

#pragma mark - Actions

- (IBAction)next:(WLButton*)sender {
    [self.view endEditing:YES];
    WLAuthorization *authorization = [WLAuthorization currentAuthorization];
    authorization.phone = phoneNumberClearing(self.phoneNumberTextField.text);
    authorization.formattedPhone = self.phoneNumberTextField.text;
    __weak typeof(self)weakSelf = self;
    [self confirmAuthorization:authorization success:^(WLAuthorization *authorization) {
        sender.loading = YES;
        [weakSelf signUpAuthorization:authorization success:^{
            sender.loading = NO;
        } failure:^(NSError *error) {
            sender.loading = NO;
        }];
    }];
}

- (void)confirmAuthorization:(WLAuthorization*)authorization success:(void (^)(WLAuthorization *authorization))success {
    __weak typeof(self)weakSelf = self;
    __weak WLConfirmView *confirmView = [WLConfirmView loadFromNib];
    confirmView.frame = self.view.frame;
    confirmView.emailLabel.text = [authorization email];
    confirmView.phoneLabel.text = [authorization fullPhoneNumber];
    [self.view addSubview:confirmView];
    [confirmView confirmationSuccess:^{
        success(authorization);
    } failure:^{
        [weakSelf setStatus:WLSignupStepStatusCancel animated:YES];
    }];
}

- (void)signUpAuthorization:(WLAuthorization*)authorization success:(WLBlock)success failure:(WLFailureBlock)failure {
	__weak typeof(self)weakSelf = self;
	[authorization signUp:^(WLAuthorization *authorization) {
        [weakSelf setStatus:WLSignupStepStatusSuccess animated:YES];
        if (success) success();
	} failure:^(NSError *error) {
		[error show];
        if (failure) failure(error);
	}];
}

- (void)signInAuthorization:(WLAuthorization*)authorization {
	[authorization signIn:^(WLUser *user) {
        
	} failure:^(NSError *error) {
		[error show];
	}];
}

- (IBAction)phoneChanged:(UITextField *)sender {
    WLAuthorization *authorization = [WLAuthorization currentAuthorization];
    authorization.phone = phoneNumberClearing(sender.text);
    authorization.formattedPhone = sender.text;
}

- (IBAction)countrySelected:(UIStoryboardSegue *)unwindSegue {
    WLCountry* selectedCountry = [unwindSegue.sourceViewController selectedCountry];
    if (selectedCountry) {
        self.country = selectedCountry;
    }
}

@end
