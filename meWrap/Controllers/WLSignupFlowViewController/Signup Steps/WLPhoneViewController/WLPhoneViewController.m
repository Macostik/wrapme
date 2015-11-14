//
//  WLPhoneNumberViewController.m
//  meWrap
//
//  Created by Ravenpod on 3/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPhoneViewController.h"
#import "WLCountriesViewController.h"
#import "WLToast.h"
#import "WLKeyboard.h"
#import "WLButton.h"
#import "WLPhoneValidation.h"
#import "WLConfirmView.h"

@interface WLPhoneViewController () <UITextFieldDelegate, WLKeyboardBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;

@property (weak, nonatomic) IBOutlet UIButton *selectCountryButton;
@property (weak, nonatomic) IBOutlet UILabel *countryCodeLabel;

@property (strong, nonatomic) Country *country;

@property (strong, nonatomic) IBOutlet WLPhoneValidation *validation;

@end

@implementation WLPhoneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.country = [Country getCurrentCountry];
    
	self.phoneNumberTextField.text = [Authorization currentAuthorization].phone;
}

- (void)setCountry:(Country *)country {
	_country = country;
    [Authorization currentAuthorization].countryCode = country.callingCode;
	[self.selectCountryButton setTitle:country.name forState:UIControlStateNormal];
	self.countryCodeLabel.text = [NSString stringWithFormat:@"+%@", country.callingCode];
    self.validation.country = country;
}

#pragma mark - Actions

- (IBAction)next:(WLButton*)sender {
    [self.view endEditing:YES];
    Authorization *authorization = [Authorization currentAuthorization];
    authorization.countryCode = self.country.callingCode;
    authorization.phone = [self.phoneNumberTextField.text clearPhoneNumber];
    authorization.formattedPhone = self.phoneNumberTextField.text;
    __weak typeof(self)weakSelf = self;
    [self confirmAuthorization:authorization success:^(Authorization *authorization) {
        sender.loading = YES;
        [weakSelf signUpAuthorization:authorization success:^{
            sender.loading = NO;
        } failure:^(NSError *error) {
            sender.loading = NO;
        }];
    }];
}

- (IBAction)selectCountry:(id)sender {
    WLCountriesViewController *controller = self.storyboard[@"WLCountriesViewController"];
    controller.selectedCountry = self.country;
    __weak typeof(self)weakSelf = self;
    [controller setSelectionBlock:^(Country *country) {
        weakSelf.country = country;
        [weakSelf.navigationController popViewControllerAnimated:NO];
    }];
    [self.navigationController pushViewController:controller animated:NO];
}

- (void)confirmAuthorization:(Authorization *)authorization success:(void (^)(Authorization *authorization))success {
    __weak typeof(self)weakSelf = self;
    [WLConfirmView showInView:self.view authorization:authorization success:success cancel:^{
        [weakSelf setStatus:WLSignupStepStatusCancel animated:NO];
    }];
}

- (void)signUpAuthorization:(Authorization *)authorization success:(WLBlock)success failure:(WLFailureBlock)failure {
	__weak typeof(self)weakSelf = self;
	[authorization signUp:^(Authorization *authorization) {
        [weakSelf setStatus:WLSignupStepStatusSuccess animated:NO];
        if (success) success();
	} failure:^(NSError *error) {
		[error show];
        if (failure) failure(error);
	}];
}

- (void)signInAuthorization:(Authorization *)authorization {
	[authorization signIn:^(User *user) {
        
	} failure:^(NSError *error) {
		[error show];
	}];
}

- (IBAction)phoneChanged:(UITextField *)sender {
    Authorization *authorization = [Authorization currentAuthorization];
    authorization.phone = [sender.text clearPhoneNumber];
    authorization.formattedPhone = sender.text;
}

@end
