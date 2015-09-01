//
//  WLCommentCell.m
//  moji
//
//  Created by Ravenpod on 3/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCommentCell.h"
#import "UIFont+CustomFonts.h"
#import "WLToast.h"
#import "WLMenu.h"
#import "UITextView+Aditions.h"
#import "UIFont+CustomFonts.h"
#import "WLTextView.h"
#import "WLEntryStatusIndicator.h"

@interface WLCommentCell ()

@property (weak, nonatomic) IBOutlet WLImageView *authorImageView;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet WLTextView *commenttextView;
@property (weak, nonatomic) IBOutlet WLEntryStatusIndicator *indicator;

@end

@implementation WLCommentCell

- (void)awakeFromNib {
	[super awakeFromNib];
    __weak typeof(self)weakSelf = self;
    self.commenttextView.textContainerInset = UIEdgeInsetsZero;
    self.commenttextView.textContainer.lineFragmentPadding = .0f;
    
    [[WLMenu sharedMenu] addView:self configuration:^(WLMenu *menu) {
        WLComment* comment = weakSelf.entry;
        if (comment.deletable) {
            [menu addDeleteItem:^(WLComment *comment) {
                weakSelf.userInteractionEnabled = NO;
                [weakSelf.entry remove:^(id object) {
                    weakSelf.userInteractionEnabled = YES;
                } failure:^(NSError *error) {
                    [error show];
                    weakSelf.userInteractionEnabled = YES;
                }];
            }];
        }
        [menu addCopyItem:^(WLComment *comment) {
            if (comment.text.nonempty) {
                [[UIPasteboard generalPasteboard] setValue:comment.text forPasteboardType:(id)kUTTypeText];
            }
        }];
        menu.entry = comment;
    }];
}

- (void)setup:(WLComment *)entry {
	self.userInteractionEnabled = YES;
    [entry markAsRead];
	self.authorNameLabel.text = entry.contributor.name;
	self.authorImageView.url = entry.contributor.picture.small;
    self.dateLabel.text = entry.createdAt.timeAgoString;
    [self.indicator updateStatusIndicator:entry];
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.firstLineHeadIndent = [[self.entry contributor] isCurrentUser] ? WLLineHeadIndent : 0;
    self.commenttextView.attributedText = [[NSAttributedString alloc]
                                            initWithString:entry.text
                                            attributes: @{NSParagraphStyleAttributeName : paragraphStyle,
                                                          NSFontAttributeName : self.commenttextView.font}];
}

@end
