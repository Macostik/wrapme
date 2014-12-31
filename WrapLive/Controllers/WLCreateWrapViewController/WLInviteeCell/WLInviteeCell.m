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
    [self.avatarView setImageName:@"default-medium-avatar" forState:WLImageViewStateEmpty];
    [self.avatarView setImageName:@"default-medium-avatar" forState:WLImageViewStateFailed];
}

- (void)setupItemData:(WLPerson*)person {
    self.nameLabel.text = person.priorityName;
    self.avatarView.url = person.priorityPicture.medium;
}

#pragma mark - Actions

- (IBAction)remove:(id)sender {
	[self.delegate inviteeCell:self didRemovePerson:self.item];
}

@end
