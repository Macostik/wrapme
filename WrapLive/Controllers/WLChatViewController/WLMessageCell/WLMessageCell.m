//
//  WLMessageCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLMessageCell.h"
#import "WLCandy.h"
#import "WLImageFetcher.h"
#import "WLUser.h"
#import "UIView+Shorthand.h"
#import "UILabel+Additions.h"

@interface WLMessageCell ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;


@end

@implementation WLMessageCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.avatarView.circled = YES;
}

- (void)setupItemData:(WLCandy*)candy {
	self.avatarView.url = candy.contributor.picture.medium;
	self.nameLabel.text = candy.contributor.name;
	self.messageLabel.text = candy.message;
	__weak typeof(self)weakSelf = self;
	[UIView performWithoutAnimation:^{
		[weakSelf.messageLabel sizeToFitHeight];
	}];
}

@end
