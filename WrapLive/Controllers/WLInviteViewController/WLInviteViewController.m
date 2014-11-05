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
#import "WLPerson.h"
#import "WLContributorsRequest.h"
#import "WLButton.h"

@interface WLInviteViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (strong, nonatomic) NSMutableArray *contacts;
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

- (NSMutableArray *)contacts {
	if (!_contacts) {
		_contacts = [NSMutableArray new];
	}
	return _contacts;
}

#pragma mark - actions

- (IBAction)addContact:(WLButton *)sender {
    self.view.userInteractionEnabled = NO;
    sender.loading = YES;
	WLContact * contact = [WLContact new];
	contact.name = self.userNameTextField.text;
	WLPerson * person = [WLPerson new];
	person.phone = self.phoneNumberTextField.text;
    person.name = self.userNameTextField.text;
	contact.persons = @[person];
	__weak typeof(self)weakSelf = self;
    [[WLContributorsRequest request:@[contact]] send:^(id object) {
        sender.loading = NO;
		if ([object count]) {
			NSError* error = [weakSelf.delegate inviteViewController:weakSelf didInviteContact:contact];
            if (error) {
                [error show];
            } else {
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }
		}
        weakSelf.view.userInteractionEnabled = YES;
    } failure:^(NSError *error) {
        sender.loading = NO;
        weakSelf.view.userInteractionEnabled = YES;
		[error show];
    }];
}

- (void)validateAddUserButton {
    self.addUserButton.active = self.userNameTextField.text.nonempty && self.phoneNumberTextField.text.length >= WLMinPhoneLenth;
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
