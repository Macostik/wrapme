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

@interface WLMessageCell () <WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLTextView *textView;
@property (weak, nonatomic) IBOutlet WLEntryStatusIndicator *indicator;

@end

@implementation WLMessageCell

+ (UIImage*)tailImageWithColor:(UIColor*)color size:(CGSize)size drawing:(void (^) (CGSize size))drawing {
    static NSDictionary *tails = nil;
    UIImage *image = [tails objectForKey:color];
    if (!image) {
        image = [UIImage draw:size opaque:NO scale:[UIScreen mainScreen].scale drawing:drawing];
        if (tails) {
            NSMutableDictionary *_tails = [tails mutableCopy];
            [_tails setObject:image forKey:color];
            tails = [_tails copy];
        } else {
            tails = [NSDictionary dictionaryWithObject:image forKey:color];
        }
    }
    return image;
}

- (void)awakeFromNib {
	[super awakeFromNib];
    self.avatarView.hidden = self.nameLabel.hidden = YES;
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
    
    self.showName = YES;
}

- (void)setShowName:(BOOL)showName {
    if (_showName != showName) {
        _showName = showName;
        self.avatarView.hidden = self.nameLabel.hidden = !showName;
        [self.nameLabel setContentCompressionResistancePriority:showName ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [self.nameLabel setContentCompressionResistancePriority:showName ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [self.textView setContentCompressionResistancePriority:showName ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        [self setNeedsLayout];
    }
}

- (void)setup:(WLMessage*)message {
    if (_showName) {
        self.avatarView.url = message.contributor.picture.small;
        self.nameLabel.text = message.contributedByCurrentUser ? WLLS(@"you") : message.contributor.name;
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
