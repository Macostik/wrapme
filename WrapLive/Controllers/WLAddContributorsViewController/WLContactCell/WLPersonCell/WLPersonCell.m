//
//  WLPhoneCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLPersonCell.h"
#import "WLUser.h"
#import "NSString+Additions.h"
#import "WLPerson.h"
#import "WLAddressBook.h"

@interface WLPersonCell ()

@property (weak, nonatomic) IBOutlet UIImageView *selectionView;
@property (nonatomic, weak) IBOutlet UILabel *typeLabel;
@property (nonatomic, weak) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UIImageView *signUpView;

@end

@implementation WLPersonCell

- (void)setupItemData:(WLPerson *)person {
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
    WLPerson *person = self.item;
	[self.delegate personCell:self didSelectPerson:person];
}

@end
