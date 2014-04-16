//
//  WLWrapCandyCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapCandyCell.h"
#import "WLCandy.h"
#import "UIImageView+ImageLoading.h"
#import "WLComment.h"
#import "WLUser.h"
#import "WLProgressBar.h"
#import "WLBorderView.h"

@interface WLWrapCandyCell ()

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UIImageView *chatLabelView;
@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;
@property (weak, nonatomic) IBOutlet WLBorderView *borderView;

@end

@implementation WLWrapCandyCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.borderView.lineWidth = 0.5f;
}

- (void)setupItemData:(WLCandy*)entry {
	self.coverView.image = nil;
	
	self.chatLabelView.hidden = entry.type == WLCandyTypeImage;
	if (entry.type == WLCandyTypeImage) {
		self.commentLabel.hidden = [entry.comments count] == 0;
		self.coverView.imageUrl = entry.picture.thumbnail;
	}
	else {
		self.commentLabel.hidden = !entry.chatMessage.length > 0;
		self.coverView.imageUrl = entry.contributor.picture.medium;
	}
	
	if (!self.commentLabel.hidden) {
		if (entry.type == WLCandyTypeImage) {
			WLComment* comment = [entry.comments lastObject];
			self.commentLabel.text = comment.text;
		}
		else {
			self.commentLabel.text = entry.chatMessage;
		}
		
	}
	
	if (entry.uploadingItem) {
		self.progressBar.superview.hidden = NO;
		self.progressBar.uploadingItem = entry.uploadingItem;
	} else {
		self.progressBar.superview.hidden = YES;
	}
}

@end
