//
//  WLMessageCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLMessageCell.h"
#import "WLCandy.h"
#import "UIImageView+ImageLoading.h"
#import "WLUser.h"
#import "UIView+Shorthand.h"

@interface WLMessageCell ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;


@end

@implementation WLMessageCell

- (void)setupItemData:(WLCandy*)candy {
	self.avatarView.imageUrl = candy.contributor.picture.medium;
	self.nameLabel.text = candy.contributor.name;
	self.messageLabel.text = candy.chatMessage;
	__weak typeof(self)weakSelf = self;
	[UIView performWithoutAnimation:^{
		weakSelf.messageLabel.height = [weakSelf.messageLabel sizeThatFits:CGSizeMake(weakSelf.messageLabel.width, CGFLOAT_MAX)].height;
	}];
}

@end
