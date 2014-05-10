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
@property (nonatomic, weak) IBOutlet UILabel* typeLabel;
@property (nonatomic, weak) IBOutlet UILabel* phoneLabel;
@property (weak, nonatomic) IBOutlet UIImageView *signUpView;

@end

@implementation WLPhoneCell

- (void)setupItemData:(WLUser*)user {
	self.typeLabel.text = [NSString stringWithFormat:@"%@:", user.phoneNumber.label];
	self.phoneLabel.text = user.phoneNumber;
	self.signUpView.hidden = !user.identifier.nonempty;
}

- (void)setChecked:(BOOL)checked {
	_checked = checked;
	[UIView beginAnimations:nil context:nil];
	self.selectionView.highlighted = checked;
	[UIView commitAnimations];
}

- (IBAction)select:(id)sender {
	[self.delegate phoneCell:self didSelectContributor:self.item];
}

@end
