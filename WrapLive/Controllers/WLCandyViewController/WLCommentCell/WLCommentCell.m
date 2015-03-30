//
//  WLCommentCell.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCommentCell.h"
#import "UIFont+CustomFonts.h"
#import "UILabel+Additions.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "UIView+GestureRecognizing.h"
#import "WLToast.h"
#import "WLMenu.h"
#import "UITextView+Aditions.h"
#import "UIFont+CustomFonts.h"
#import "TTTAttributedLabel.h"
#import "WLTextView.h"


@interface WLCommentCell ()

@property (weak, nonatomic) IBOutlet WLImageView *authorImageView;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet WLTextView *commenttextView;

@end

@implementation WLCommentCell

- (void)awakeFromNib {
	[super awakeFromNib];
    __weak typeof(self)weakSelf = self;
    self.layer.geometryFlipped = YES;
    self.commenttextView.textContainerInset = UIEdgeInsetsZero;
    
    [self.authorImageView setImageName:@"default-medium-avatar" forState:WLImageViewStateEmpty];
    [self.authorImageView setImageName:@"default-medium-avatar" forState:WLImageViewStateFailed];
    
    [[WLMenu sharedMenu] addView:self configuration:^void (WLMenu *menu, BOOL *vibrate) {
        WLComment* comment = weakSelf.entry;
        if (comment.deletable) {
            [menu addDeleteItem:^{
                weakSelf.userInteractionEnabled = NO;
                [weakSelf.entry remove:^(id object) {
                    weakSelf.userInteractionEnabled = YES;
                } failure:^(NSError *error) {
                    [error show];
                    weakSelf.userInteractionEnabled = YES;
                }];
            }];
        } else {
            *vibrate = NO;
            [WLToast showWithMessage:WLLS(@"Cannot delete comment not posted by you.")];
        }
    }];
}

- (void)setup:(WLComment *)entry {
	self.userInteractionEnabled = YES;
    [[WLEntryManager manager].context processPendingChanges];
    if (entry.unread) entry.unread = NO;
	self.authorNameLabel.text = entry.contributor.name;
    [self.commenttextView determineHyperLink:entry.text];
	self.authorImageView.url = entry.contributor.picture.small;
    self.dateLabel.text = entry.createdAt.timeAgoString;
}

@end
