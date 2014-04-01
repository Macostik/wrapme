//
//  WLCommentCell.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCommentCell.h"
#import "WLComment.h"
#import "WLUser.h"
#import "UIImageView+ImageLoading.h"

@interface WLCommentCell()
@property (weak, nonatomic) IBOutlet UIImageView *authorImageView;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;

@end

@implementation WLCommentCell

- (void)setupItemData:(WLComment *)entry {
	self.authorNameLabel.text = entry.author.name;
	self.commentLabel.text = entry.text;
	self.authorImageView.imageUrl = entry.author.picture.thumbnail;
}

@end
