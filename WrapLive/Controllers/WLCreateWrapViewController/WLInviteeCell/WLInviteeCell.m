//
//  WLInviteeCell.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/19/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLInviteeCell.h"
#import "UIView+Shorthand.h"
#import "NSString+Additions.h"
#import "WLImageFetcher.h"
#import "WLPicture.h"
#import "WLPerson.h"
#import "WLUser.h"

@interface WLInviteeCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;

@end

@implementation WLInviteeCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.avatarView.circled = YES;
}

- (void)setupItemData:(WLPerson*)person {
    self.nameLabel.text = person.prioritetName;
    self.avatarView.url = person.prioritetPicture.medium;
    if(!self.avatarView.url.nonempty) {
        self.avatarView.image = [UIImage imageNamed:@"default-medium-avatar"];
    }
}

#pragma mark - Actions

- (IBAction)remove:(id)sender {
	[self.delegate inviteeCell:self didRemovePerson:self.item];
}

@end
