//
//  WLInviteViewContraller.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 6/3/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLInviteViewController.h"
#import "WLAddressBook.h"
#import "WLAPIManager.h"
#import "WLUser.h"
#import "NSString+Additions.h"
#import "UIButton+Additions.h"
#import "NSArray+Additions.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLContributorsRequest.h"
#import "WLButton.h"

@interface WLInviteViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (weak, nonatomic) IBOutlet UIButton *addUserButton;

@end

@implementation WLInviteViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self.userNameTextField becomeFirstResponder];
    [self validateAddUserButton];
}

#pragma mark - actions

- (IBAction)addContact:(WLButton *)sender {
    self.view.userInteractionEnabled = NO;
    sender.loading = YES;
	WLAddressBookRecord * contact = [WLAddressBookRecord new];
	contact.name = self.userNameTextField.text;
	WLAddressBookPhoneNumber * person = [WLAddressBookPhoneNumber new];
	person.phone = self.phoneNumberTextField.text;
    person.name = self.userNameTextField.text;
	contact.phoneNumbers = @[person];
	__weak typeof(self)weakSelf = self;
    [[WLContributorsRequest request:@[contact]] send:^(id object) {
        sender.loading = NO;
		if ([object count]) {
			[weakSelf.delegate inviteViewController:weakSelf didInviteContact:contact];
		}
        weakSelf.view.userInteractionEnabled = YES;
    } failure:^(NSError *error) {
        sender.loading = NO;
        weakSelf.view.userInteractionEnabled = YES;
		[error show];
    }];
}

- (void)validateAddUserButton {
    self.addUserButton.active = self.userNameTextField.text.nonempty && self.phoneNumberTextField.text.length >= WLAddressBookPhoneNumberMinimumLength;
}

- (IBAction)textChanged:(UITextField *)sender {
    [self validateAddUserButton];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.userNameTextField) {
        [self.phoneNumberTextField becomeFirstResponder];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSString* resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (textField == self.userNameTextField) {
        return resultString.length <= WLProfileNameLimit;
    } else {
        return resultString.length <= WLPhoneNumberLimit;
    }
}

@end
