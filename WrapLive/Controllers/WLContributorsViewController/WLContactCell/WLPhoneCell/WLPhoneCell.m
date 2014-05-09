//
//  WLPhoneCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLPhoneCell.h"
#import "WLUser.h"

@interface WLPhoneCell ()

@property (weak, nonatomic) IBOutlet UIImageView *selectionView;
@property (nonatomic, weak) IBOutlet UILabel* typeLabel;
@property (nonatomic, weak) IBOutlet UILabel* phoneLabel;

@end

@implementation WLPhoneCell

- (void)setupItemData:(WLUser*)user {
	self.phoneLabel.text = user.phoneNumber;
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
