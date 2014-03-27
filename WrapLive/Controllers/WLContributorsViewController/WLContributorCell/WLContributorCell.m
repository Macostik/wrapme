//
//  WLContributorCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLContributorCell.h"
#import "WLUser.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface WLContributorCell ()

@property (weak, nonatomic) IBOutlet UIView *selectionView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;

@end

@implementation WLContributorCell

- (void)setupItemData:(WLUser*)user {
	self.nameLabel.text = user.name;
	[self.avatarView setImageWithURL:[NSURL URLWithString:user.avatar]];
}

#pragma mark - Actions

- (IBAction)remove:(id)sender {
	[self.delegate contributorCell:self didRemoveContributor:self.item];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
	self.selectionView.hidden = !selected;
}

@end
