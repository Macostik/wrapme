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
#import "UIColor+CustomColors.h"

@interface WLContributorCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;
@property (weak, nonatomic) IBOutlet UIButton *resendInviteButton;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *removeButtonTop;

@end

@implementation WLContributorCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.avatarView setImageName:@"default-medium-avatar" forState:WLImageViewStateEmpty];
    [self.avatarView setImageName:@"default-medium-avatar" forState:WLImageViewStateFailed];
    self.resendInviteButton.layer.borderColor = self.removeButton.layer.borderColor = [UIColor WL_grayLight].CGColor;
    self.resendInviteButton.layer.borderWidth = self.removeButton.layer.borderWidth = 1;
    self.resendInviteButton.layer.cornerRadius = self.removeButton.layer.cornerRadius = 6;
    self.resendInviteButton.clipsToBounds = self.removeButton.clipsToBounds = YES;
}

- (void)setup:(WLUser*)user {
	NSString * userNameText = [user isCurrentUser] ? WLLS(@"You") : user.name;
	BOOL isCreator = NO;
	if ([self.delegate respondsToSelector:@selector(contributorCell:isCreator:)]) {
		isCreator = [self.delegate contributorCell:self isCreator:user];
	}
	self.nameLabel.text = isCreator ? [NSString stringWithFormat:WLLS(@"%@ (Owner)"), userNameText] : userNameText;
    
    self.phoneLabel.text = user.securePhones;
    self.avatarView.url = user.picture.small;
}

- (void)setDeletable:(BOOL)deletable {
	_deletable = deletable;
    self.removeButton.hidden = !deletable;
    self.removeButtonTop.constant = deletable ? self.avatarView.y : -self.removeButton.height;
    if (deletable) {
        WLUser *user = self.entry;
        self.resendInviteButton.hidden = [user.devices match:^BOOL(WLDevice *device) {
            return device.activated;
        }];
    } else {
        self.resendInviteButton.hidden = YES;
    }
}

#pragma mark - Actions

- (IBAction)remove:(id)sender {
	[self.delegate contributorCell:self didRemoveContributor:self.entry];
}

- (IBAction)resendInvite:(id)sender {
    [self.delegate contributorCell:self didInviteContributor:self.entry];
}

@end
