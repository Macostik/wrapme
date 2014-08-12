//
//  WLContributorCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLContributorCell.h"
#import "WLImageFetcher.h"
#import "UIView+Shorthand.h"
#import "NSString+Additions.h"
#import "WLEntryManager.h"

@interface WLContributorCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;

@end

@implementation WLContributorCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.avatarView.circled = YES;
}

- (void)setupItemData:(WLUser*)user {
	NSString * userNameText = [user isCurrentUser] ? @"You" : user.name;
	BOOL isCreator = NO;
	if ([self.delegate respondsToSelector:@selector(contributorCell:isCreator:)]) {
		isCreator = [self.delegate contributorCell:self isCreator:user];
	}
	self.nameLabel.text = isCreator ? [NSString stringWithFormat:@"%@ (Owner)", userNameText] : userNameText;
	if (self.nameLabel.text.empty) {
		self.nameLabel.text = user.phone;
	}
    self.avatarView.url = user.picture.medium;
    if (!self.avatarView.url.nonempty) {
        self.avatarView.image = [UIImage imageNamed:@"default-medium-avatar"];
    }
}

- (void)setDeletable:(BOOL)deletable {
	_deletable = deletable;
    if (deletable) {
        [self.removeButton removeFromSuperview];
    }
}

#pragma mark - Actions

- (IBAction)remove:(id)sender {
	[self.delegate contributorCell:self didRemoveContributor:self.item];
}

@end
