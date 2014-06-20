//
//  WLPhoneCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLPhoneCell.h"
#import "WLUser.h"
#import "NSString+Additions.h"
#import "WLAddressBook.h"

@interface WLPhoneCell ()

@property (weak, nonatomic) IBOutlet UIImageView *selectionView;
@property (nonatomic, weak) IBOutlet UILabel *typeLabel;
@property (nonatomic, weak) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UIImageView *signUpView;

@end

@implementation WLPhoneCell

- (void)setupItemData:(WLPhone *)phone {
	self.typeLabel.text = [NSString stringWithFormat:@"%@:", WLString(phone.number.label)];
	self.phoneLabel.text = phone.number;
	self.signUpView.hidden = !phone.user;
}

- (void)setChecked:(BOOL)checked {
	_checked = checked;
	[UIView beginAnimations:nil context:nil];
	self.selectionView.highlighted = checked;
	[UIView commitAnimations];
}

- (IBAction)select:(id)sender {
    WLPhone *phone = self.item;
	[self.delegate phoneCell:self didSelectPhone:phone];
}

@end
