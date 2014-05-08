//
//  WLContributorCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLContributorCell.h"
#import "WLUser.h"
#import "UIImageView+ImageLoading.h"
#import "UIView+Shorthand.h"
#import "NSString+Additions.h"

@interface WLContributorCell ()

@property (weak, nonatomic) IBOutlet UIImageView *selectionView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;

@end

@implementation WLContributorCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.avatarView.circled = YES;
}

- (void)setupItemData:(WLUser*)user {
	self.nameLabel.text = [user isCurrentUser] ? @"You" : user.name;
	if (user.picture.medium.nonempty) {
		self.avatarView.imageUrl = user.picture.medium;
	} else {
		self.avatarView.image = [UIImage imageNamed:@"ic_default_profile"];
	}
}

- (void)setDeletable:(BOOL)deletable {
	_deletable = deletable;
	self.removeButton.hidden = !deletable;
}

#pragma mark - Actions

- (IBAction)remove:(id)sender {
	[self.delegate contributorCell:self didRemoveContributor:self.item];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
	self.selectionView.highlighted = selected;
}

@end
