//
//  WLInviteeCell.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/19/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLInviteeCell.h"
#import "UIView+Shorthand.h"
#import "WLAddressBook.h"
#import "NSString+Additions.h"
#import "WLImageFetcher.h"
#import "WLPicture.h"

@interface WLInviteeCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;

@end

@implementation WLInviteeCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.avatarView.circled = YES;
}

- (void)setupItemData:(WLPhone*)phone {
	self.nameLabel.text = phone.name;
	if (self.nameLabel.text.empty) {
		self.nameLabel.text = phone.number;
	}
	if (phone.picture.medium.nonempty) {
		self.avatarView.url = phone.picture.medium;
	} else {
		self.avatarView.url = nil;
		self.avatarView.image = [UIImage imageNamed:@"default-medium-avatar"];
	}
}

- (void)setDeletable:(BOOL)deletable {
	_deletable = deletable;
	self.removeButton.hidden = !deletable;
}

#pragma mark - Actions

- (IBAction)remove:(id)sender {
	[self.delegate inviteeCell:self didRemovePhone:self.item];
}

@end
