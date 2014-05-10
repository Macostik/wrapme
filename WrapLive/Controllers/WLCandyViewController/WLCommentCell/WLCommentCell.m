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
#import "UILabel+Additions.h"
#import "NSDate+Additions.h"
#import "UIAlertView+Blocks.h"
#import "WLAPIManager.h"
#import "WLWrapBroadcaster.h"
#import "UIActionSheet+Blocks.h"

@interface WLCommentCell()

@property (weak, nonatomic) IBOutlet UIImageView *authorImageView;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;

@end

@implementation WLCommentCell

+ (UIFont *)commentFont {
	static UIFont* commentFont = nil;
	if (!commentFont) {
		commentFont = [UIFont lightFontOfSize:15];
	}
	return commentFont;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	self.commentLabel.font = [WLCommentCell commentFont];
	self.authorImageView.layer.cornerRadius = self.authorImageView.height/2.0f;
	UILongPressGestureRecognizer* removeGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(remove:)];
	[self addGestureRecognizer:removeGestureRecognizer];
}

- (void)setupItemData:(WLComment *)entry {
	self.authorNameLabel.text = [NSString stringWithFormat:@"%@, %@", entry.contributor.name, entry.createdAt.timeAgoString];
	self.commentLabel.text = entry.text;
	[self.commentLabel sizeToFitHeight];
	self.authorImageView.imageUrl = entry.contributor.picture.medium;
}

- (void)remove:(UILongPressGestureRecognizer*)sender {
	if (sender.state == UIGestureRecognizerStateBegan && self.userInteractionEnabled) {
		__weak typeof(self)weakSelf = self;
		WLComment* comment = weakSelf.item;
		if ([comment.contributor isCurrentUser]) {
			[UIActionSheet showWithTitle:[NSString stringWithFormat:@"Comment: %@", comment.text] destructive:@"Delete" completion:^(NSUInteger index) {
				[UIActionSheet showWithCondition:@"Are you sure you want to delete this comment?" completion:^(NSUInteger index) {
					weakSelf.userInteractionEnabled = NO;
					[weakSelf.candy removeComment:comment wrap:weakSelf.wrap success:^(id object) {
						weakSelf.userInteractionEnabled = YES;
					} failure:^(NSError *error) {
						[error show];
						weakSelf.userInteractionEnabled = YES;
					}];
				}];
			}];
		}
	}
}

@end
