//
//  WLCommentCell.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCommentCell.h"
#import "WLImageFetcher.h"
#import "UIView+Shorthand.h"
#import "UIFont+CustomFonts.h"
#import "UILabel+Additions.h"
#import "NSDate+Additions.h"
#import "UIAlertView+Blocks.h"
#import "WLAPIManager.h"
#import "WLWrapBroadcaster.h"
#import "UIActionSheet+Blocks.h"
#import "UIView+GestureRecognizing.h"
#import "WLToast.h"
#import "WLEntryManager.h"
#import "WLMenu.h"
#import "NSString+Additions.h"
#import "WLCircleProgressBar.h"
#import "WLInternetConnectionBroadcaster.h"

@interface WLCommentCell ()

@property (weak, nonatomic) IBOutlet WLImageView *authorImageView;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet WLCircleProgressBar *circleProgressBar;
@property (strong, nonatomic) WLMenu* menu;

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
    __weak typeof(self)weakSelf = self;
    self.menu = [WLMenu menuWithView:self configuration:^BOOL(WLMenu *menu) {
        WLComment* comment = weakSelf.item;
        if ([comment.contributor isCurrentUser]) {
            [menu addItem:@"Delete" block:^{
                weakSelf.userInteractionEnabled = NO;
                [weakSelf.item remove:^(id object) {
                    weakSelf.userInteractionEnabled = YES;
                } failure:^(NSError *error) {
                    [error show];
                    weakSelf.userInteractionEnabled = YES;
                }];
            }];
            return YES;
        } else {
            [WLToast showWithMessage:@"Cannot delete comment not posted by you."];
            return NO;
        }
    }];
}

- (void)setupItemData:(WLComment *)entry {
	self.userInteractionEnabled = YES;
	self.authorNameLabel.text = [NSString stringWithFormat:@"%@, %@", WLString(entry.contributor.name), WLString(entry.createdAt.timeAgoString)];
	self.commentLabel.text = entry.text;
	[self.commentLabel sizeToFitHeight];
    __weak typeof(self)weakSelf = self;
    [self.authorImageView setUrl:entry.contributor.picture.medium completion:^(UIImage *image, BOOL cached, NSError *error) {
        if (error) {
            weakSelf.authorImageView.image = [UIImage imageNamed:@"default-medium-avatar"];
        }
    }];
	self.menu.vibrate = [entry.contributor isCurrentUser];
    self.circleProgressBar.operation = entry.uploading.operation;
    if (![WLInternetConnectionBroadcaster broadcaster].reachable && !entry.uploaded) {
        self.circleProgressBar.progress = .15f;
    }
}

@end
