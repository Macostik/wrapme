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
#import "WLSession.h"
#import "WLAuthorization.h"
#import "WLTestUserPicker.h"
#import "WLNavigation.h"
#import "WLToast.h"
#import "WLHomeViewController.h"
#import "WLKeyboard.h"
#import "WLAuthorizationRequest.h"
#import "WLButton.h"
#import "WLPhoneValidation.h"
#import "RMPhoneFormat.h"

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
	if ([WLAPIManager instance].environment.useTestUsers) {
		__weak typeof(self)weakSelf = self;
		run_after(0.1, ^{
			UIButton* testUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
			testUserButton.frame = CGRectMake(0, weakSelf.view.height - 44, weakSelf.view.width, 44);
			[testUserButton setTitle:@"Test user (for debug only)" forState:UIControlStateNormal];
			[testUserButton setTitleColor:[UIColor WL_orangeColor] forState:UIControlStateNormal];
			[testUserButton addTarget:weakSelf action:@selector(selectTestUser) forControlEvents:UIControlEventTouchUpInside];
			[weakSelf.view addSubview:testUserButton];
		});
	}
}

- (void)setCountry:(WLCountry *)country {
	_country = country;
    [WLAuthorization currentAuthorization].countryCode = country.callingCode;
	[self.selectCountryButton setTitle:country.name forState:UIControlStateNormal];
	self.countryCodeLabel.text = [NSString stringWithFormat:@"+%@", country.callingCode];
    self.validation.format = [[RMPhoneFormat alloc] initWithDefaultCountry:[country.code lowercaseString]];
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight/2.0f;
}

#pragma mark - Actions

- (IBAction)editPhoneNumber:(UIStoryboardSegue*)segue {
    
}

- (IBAction)next:(WLButton*)sender {
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
	NSString* confirmationMessage = [NSString stringWithFormat:@"%@\n%@\nIs this correct?",[authorization fullPhoneNumber], [authorization email]];
	[UIAlertView showWithTitle:@"Confirm your details" message:confirmationMessage buttons:@[@"Edit",@"Yes"] completion:^(NSUInteger index) {
		if (index == 1) {
			success(authorization);
		}
	}];
}

- (void)signUpAuthorization:(WLAuthorization*)authorization success:(WLBlock)success failure:(WLFailureBlock)failure {
	__weak typeof(self)weakSelf = self;
	[authorization signUp:^(WLAuthorization *authorization) {
		WLActivationViewController *controller = [WLActivationViewController instantiate:weakSelf.storyboard];
        controller.authorization = authorization;
		[weakSelf.navigationController pushViewController:controller animated:YES];
        if (success) success();
	} failure:^(NSError *error) {
		[error show];
        if (failure) failure(error);
	}];
}

- (void)signInAuthorization:(WLAuthorization*)authorization {
	[authorization signIn:^(WLUser *user) {
        [UIWindow mainWindow].rootViewController = [[UIStoryboard storyboardNamed:WLMainStoryboard] instantiateInitialViewController];
	} failure:^(NSError *error) {
		[error show];
	}];
}

- (IBAction)phoneChanged:(UITextField *)sender {
    WLAuthorization *authorization = [WLAuthorization currentAuthorization];
    authorization.phone = phoneNumberClearing(sender.text);
    authorization.formattedPhone = sender.text;
}

- (void)selectTestUser {
	__weak typeof(self)weakSelf = self;
	[WLTestUserPicker showInView:self.view selection:^(WLAuthorization *authorization) {
		[weakSelf confirmAuthorization:authorization success:^(WLAuthorization *authorization) {
			if (authorization.password.nonempty) {
				[weakSelf signInAuthorization:authorization];
			} else {
				[weakSelf signUpAuthorization:authorization success:nil failure:nil];
			}
		}];
	}];
}

- (IBAction)countrySelected:(UIStoryboardSegue *)unwindSegue {
    WLCountry* selectedCountry = [unwindSegue.sourceViewController selectedCountry];
    if (selectedCountry) {
        self.country = selectedCountry;
    }
}

@end
