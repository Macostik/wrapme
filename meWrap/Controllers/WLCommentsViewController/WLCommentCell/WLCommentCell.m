//
//  WLCommentCell.m
//  meWrap
//
//  Created by Ravenpod on 3/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCommentCell.h"
#import "WLToast.h"

@interface WLCommentCell ()

@property (weak, nonatomic) IBOutlet ImageView *authorImageView;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *commenttextView;
@property (weak, nonatomic) IBOutlet EntryStatusIndicator *indicator;

@end

@implementation WLCommentCell

- (void)awakeFromNib {
	[super awakeFromNib];
    __weak typeof(self)weakSelf = self;
    [[FlowerMenu sharedMenu] registerView:self constructor:^(FlowerMenu *menu) {
        Comment *comment = weakSelf.entry;
        if (comment.deletable) {
            [menu addDeleteAction:^(Comment *comment) {
                weakSelf.userInteractionEnabled = NO;
                [weakSelf.entry delete:^(id object) {
                    weakSelf.userInteractionEnabled = YES;
                } failure:^(NSError *error) {
                    [error show];
                    weakSelf.userInteractionEnabled = YES;
                }];
            }];
        }
        [menu addCopyAction:^(Comment *comment) {
            if (comment.text.nonempty) {
                [[UIPasteboard generalPasteboard] setValue:comment.text forPasteboardType:(id)kUTTypeText];
            }
        }];
        menu.entry = comment;
    }];
}

- (void)setup:(Comment *)entry {
	self.userInteractionEnabled = YES;
    [entry markAsUnread:NO];
	self.authorNameLabel.text = entry.contributor.name;
	self.authorImageView.url = entry.contributor.avatar.small;
    self.dateLabel.text = entry.createdAt.timeAgoString;
    [self.indicator updateStatusIndicator:entry];
    self.commenttextView.text = entry.text;
}

@end
