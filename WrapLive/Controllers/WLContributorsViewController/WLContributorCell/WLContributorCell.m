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
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

@end

@implementation WLContributorCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.avatarView setImageName:@"default-medium-avatar" forState:WLImageViewStateEmpty];
    [self.avatarView setImageName:@"default-medium-avatar" forState:WLImageViewStateFailed];
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
}

#pragma mark - Actions

- (IBAction)remove:(id)sender {
	[self.delegate contributorCell:self didRemoveContributor:self.entry];
}

@end
