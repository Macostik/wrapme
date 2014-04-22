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
#import "UIView+Shorthand.h"
#import "UIFont+CustomFonts.h"

@interface WLCommentCell()

@property (weak, nonatomic) IBOutlet UIImageView *authorImageView;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;

@end

@implementation WLCommentCell

+ (UIFont *)commentFont {
	static UIFont* commentFont = nil;
	if (!commentFont) {
		commentFont = [UIFont lightFontOfSize:12];
	}
	return commentFont;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	self.commentLabel.font = [WLCommentCell commentFont];
}

- (void)setupItemData:(WLComment *)entry {
	self.authorNameLabel.text = entry.contributor.name;
	self.commentLabel.text = entry.text;
	self.commentLabel.height = [self.commentLabel sizeThatFits:CGSizeMake(self.commentLabel.width, CGFLOAT_MAX)].height;
	NSLog(@"link:contributor %@", entry.contributor.picture.medium);
	self.authorImageView.imageUrl = entry.contributor.picture.medium;
}

@end
