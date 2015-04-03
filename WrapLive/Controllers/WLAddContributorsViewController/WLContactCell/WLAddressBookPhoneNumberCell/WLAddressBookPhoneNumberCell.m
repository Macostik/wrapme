//
//  WLPhoneCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAddressBookPhoneNumberCell.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLAddressBook.h"

@interface WLAddressBookPhoneNumberCell ()

@property (weak, nonatomic) IBOutlet UIImageView *selectionView;
@property (nonatomic, weak) IBOutlet UILabel *typeLabel;
@property (nonatomic, weak) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UIImageView *signUpView;

@end

@implementation WLAddressBookPhoneNumberCell

- (void)setupItemData:(WLAddressBookPhoneNumber *)person {
	self.typeLabel.text = [NSString stringWithFormat:@"%@:", WLString(person.phone.label)];
	self.phoneLabel.text = person.phone;
	self.signUpView.hidden = !person.user;
}

- (void)setChecked:(BOOL)checked {
	_checked = checked;
	[UIView beginAnimations:nil context:nil];
	self.selectionView.highlighted = checked;
	[UIView commitAnimations];
}

- (IBAction)select:(id)sender {
    WLAddressBookPhoneNumber *person = self.item;
	[self.delegate personCell:self didSelectPerson:person];
}

@end
