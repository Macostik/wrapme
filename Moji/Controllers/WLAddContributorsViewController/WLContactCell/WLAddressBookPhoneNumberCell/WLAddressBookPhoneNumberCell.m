//
//  WLPhoneCell.m
//  moji
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

- (void)setupItemData:(WLAddressBookPhoneNumber *)person {
	self.typeLabel.text = [NSString stringWithFormat:@"%@:", WLString(person.phone.label)];
	self.phoneLabel.text = person.phone;
}

- (void)setChecked:(BOOL)checked {
	_checked = checked;
	[UIView beginAnimations:nil context:nil];
	self.selectionView.selected = checked;
	[UIView commitAnimations];
}

- (IBAction)select:(id)sender {
    WLAddressBookPhoneNumber *person = self.item;
	[self.delegate personCell:self didSelectPerson:person];
}

@end
