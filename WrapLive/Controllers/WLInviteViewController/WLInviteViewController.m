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

@interface WLInviteViewController ()

@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (strong, nonatomic) NSMutableArray *contacts;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation WLInviteViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self.phoneNumberTextField becomeFirstResponder];
}

- (NSMutableArray *)contacts {
	if (!_contacts) {
		_contacts = [NSMutableArray new];
	}
	return _contacts;
}

#pragma mark - actions

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)addContact:(UIButton *)sender {
	WLContact * contact = [WLContact new];
	contact.name = @"";
	WLUser * user = [WLUser new];
	user.phoneNumber = self.phoneNumberTextField.text;
	contact.users = @[user];
	[self.spinner startAnimating];
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] contributors:[NSArray arrayWithObject:contact] success:^(NSArray *array) {
		for (WLContact * cont in array) {
			[weakSelf.contacts addObject:cont];
		}
		if (weakSelf.phoneNumberBlock && weakSelf.contacts.nonempty) {
			weakSelf.phoneNumberBlock (weakSelf.contacts);
		}
		[weakSelf.spinner stopAnimating];
		[weakSelf.navigationController popViewControllerAnimated:YES];
	} failure:^(NSError *error) {
		[weakSelf.spinner stopAnimating];
		[error show];
	}];
}

@end
