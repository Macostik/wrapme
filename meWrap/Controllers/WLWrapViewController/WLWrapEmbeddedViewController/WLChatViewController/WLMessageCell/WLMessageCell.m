//
//  WLMessageCell.m
//  meWrap
//
//  Created by Ravenpod on 09.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLMessageCell.h"
#import "UIFont+CustomFonts.h"
#import "UITextView+Aditions.h"
#import "UIFont+CustomFonts.h"
#import "WLTextView.h"
#import "UIImage+Drawing.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLEntryStatusIndicator.h"
#import "WLMenu.h"
#import "WLLayoutPrioritizer.h"

@interface WLMessageCell () <WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLTextView *textView;
@property (weak, nonatomic) IBOutlet WLEntryStatusIndicator *indicator;

@end

@implementation WLMessageCell

- (void)awakeFromNib {
	[super awakeFromNib];
    self.textView.textContainerInset = UIEdgeInsetsZero;
    self.textView.textContainer.lineFragmentPadding = .0;
    __weak typeof(self)weakSelf = self;
    [[WLMenu sharedMenu] addView:self configuration:^(WLMenu *menu) {
        [menu addCopyItem:^(WLMessage *message) {
            if (message.text.nonempty) {
                [[UIPasteboard generalPasteboard] setValue:message.text forPasteboardType:(id)kUTTypeText];
            }
        }];
        menu.entry = weakSelf.entry;
    }];
}

- (void)setup:(WLMessage*)message {
    if (self.nameLabel) {
        self.avatarView.url = message.contributor.picture.small;
        self.nameLabel.text = message.contributor.name;
    }
    self.timeLabel.text = [message.createdAt stringWithTimeStyle:NSDateFormatterShortStyle];
    [self.textView determineHyperLink:message.text];
    if (self.indicator) {
        [self.indicator updateStatusIndicator:message];
    }
    
    WLMenu *menu = [WLMenu sharedMenu];
    if (menu.visible) {
        [menu hide];
    }
}

@end
