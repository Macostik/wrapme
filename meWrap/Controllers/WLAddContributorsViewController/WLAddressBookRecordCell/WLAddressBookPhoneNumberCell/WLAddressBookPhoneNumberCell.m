//
//  WLPhoneCell.m
//  meWrap
//
//  Created by Ravenpod on 09.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAddressBookPhoneNumberCell.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLAddressBook.h"

@interface WLAddressBookPhoneNumberCell ()

@property (weak, nonatomic) IBOutlet UIButton *selectionView;
@property (nonatomic, weak) IBOutlet UILabel *typeLabel;
@property (nonatomic, weak) IBOutlet UILabel *phoneLabel;

@end

@implementation WLAddressBookPhoneNumberCell

- (void)setup:(WLAddressBookPhoneNumber *)phoneNumber {
	self.typeLabel.text = [NSString stringWithFormat:@"%@:", WLString(phoneNumber.phone.label)];
	self.phoneLabel.text = phoneNumber.phone;
}

- (void)setChecked:(BOOL)checked {
	_checked = checked;
	[UIView beginAnimations:nil context:nil];
	self.selectionView.selected = checked;
	[UIView commitAnimations];
}

@end
