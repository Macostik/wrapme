//
//  WLMessageCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLMessageCell.h"
#import "UILabel+Additions.h"
#import "UIFont+CustomFonts.h"
#import "UITextView+Aditions.h"
#import "UIFont+CustomFonts.h"
#import "WLTextView.h"
#import "UIImage+Drawing.h"
#import "WLIconView.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLEntryStatusIndicator.h"
#import "WLMenu.h"

@interface WLMessageCell () <WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLTextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *tailView;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImageView;
@property (weak, nonatomic) IBOutlet WLEntryStatusIndicator *indicator;

@end

@implementation WLMessageCell

+ (UIImage*)bubbleImageWithColor:(UIColor*)color {
    static NSMutableDictionary *images = nil;
    UIImage *image = [images objectForKey:color];
    if (!image) {
        image = [[UIImage draw:CGSizeMake(11, 11) opaque:YES scale:[UIScreen mainScreen].scale drawing:^(CGSize size) {
            [[UIColor whiteColor] setFill];
            [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, size.width, size.height)] fill];
            [color setFill];
            [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:5] fill];
        }] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5) resizingMode:UIImageResizingModeStretch];
        if (!images) {
            images = [NSMutableDictionary dictionary];
        }
        images[color] = image;
    }
    return image;
}

- (void)awakeFromNib {
	[super awakeFromNib];
    self.avatarView.hidden = self.nameLabel.hidden = YES;
    [self.avatarView setImageName:@"default-small-avatar" forState:WLImageViewStateEmpty];
    [self.avatarView setImageName:@"default-small-avatar" forState:WLImageViewStateFailed];
    self.textView.textContainerInset = UIEdgeInsetsZero;
    self.textView.textContainer.lineFragmentPadding = .0;
    self.bubbleImageView.image = [WLMessageCell bubbleImageWithColor:self.bubbleImageView.backgroundColor];
    
    __weak typeof(self)weakSelf = self;
    [[WLMenu sharedMenu] addView:self configuration:^WLEntry *(WLMenu *menu, BOOL *vibrate) {
        [menu addCopyItem:^(WLMessage *message) {
            if (message.text.nonempty) {
                [[UIPasteboard generalPasteboard] setValue:message.text forPasteboardType:(id)kUTTypeText];
            }
        }];
        return weakSelf.entry;
    }];
    
    self.showName = YES;
}

- (void)setShowName:(BOOL)showName {
    if (_showName != showName) {
        _showName = showName;
        self.avatarView.hidden = self.nameLabel.hidden = self.tailView.hidden = !showName;
        [self.nameLabel setContentCompressionResistancePriority:showName ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [self.textView setContentCompressionResistancePriority:showName ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
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
}

@end
