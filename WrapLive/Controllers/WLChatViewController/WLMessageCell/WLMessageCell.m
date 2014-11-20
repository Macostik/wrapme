//
//  WLMessageCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLMessageCell.h"
#import "WLCandy.h"
#import "WLImageFetcher.h"
#import "WLUser.h"
#import "UIView+Shorthand.h"
#import "UILabel+Additions.h"
#import "UIFont+CustomFonts.h"
#import "WLUser+Extended.h"
#import "NSString+Additions.h"
#import "NSDate+Formatting.h"
#import "UITextView+Aditions.h"
#import "UIFont+CustomFonts.h"
#import "WLAPIRequest.h"
#import "UIDevice+SystemVersion.h"
#import "UIColor+CustomColors.h"
#import "TTTAttributedLabel.h"

@interface WLMessageCell () <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewConstraint;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *textLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topTextLabelConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImageView;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topAvatarConstraint;

@end

@implementation WLMessageCell

- (void)awakeFromNib {
	[super awakeFromNib];
    self.avatarView.hidden = self.nameLabel.hidden = self.dayLabel.hidden = YES;
    self.textLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.bubbleImageView.image = [self.bubbleImageView.image resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
}

- (void)setShowName:(BOOL)showName {
    [self setShowName:showName showDay:_showDay];
}

- (void)setShowDay:(BOOL)showDay {
    [self setShowName:_showName showDay:showDay];
}

- (void)setShowName:(BOOL)showName showDay:(BOOL)showDay {
    _showDay = showDay;
    _showName = showName;
    self.dayLabel.hidden = !showDay;
    self.topAvatarConstraint.constant = showDay ? self.dayLabel.height : (showName ? WLMessageCellBottomConstraint : 0);
    self.avatarView.hidden = !showName;
    self.nameLabel.hidden = !showName;
    self.topTextLabelConstraint.constant = showName ? WLMessageNameInset : 0;
}

- (void)setup:(WLMessage*)message {
    
    if (_showName) {
        __weak WLImageView* avatarView = self.avatarView;
        avatarView.url = message.contributor.picture.small;
        [avatarView setFailure:^(NSError* error) {
            avatarView.image = [UIImage imageNamed:@"default-small-avatar"];
        }];
        if (!avatarView.url.nonempty) {
            avatarView.image = [UIImage imageNamed:@"default-small-avatar"];
        }
        self.nameLabel.text = [message.contributor isCurrentUser] ? @"You" : message.contributor.name;
    }
	
    self.timeLabel.text = [message.createdAt stringWithFormat:@"hh:mmaa"];
    if (_showDay) {
        self.dayLabel.text = [message.createdAt stringWithFormat:@"MMM d, yyyy"];
    }
    
    self.textLabel.text = message.text;
    
    CGSize maxSize = CGSizeMake(WLMaxTextViewWidth, CGFLOAT_MAX);
    CGFloat textWidth = [self.textLabel sizeThatFits:maxSize].width;
    CGFloat constraintValue = [self constraintForWidth:textWidth];
    if (_showName) {
        CGFloat nameWidth = [self.nameLabel sizeThatFits:maxSize].width;
        constraintValue = MIN(constraintValue, [self constraintForWidth:nameWidth]);
    }
    self.textViewConstraint.constant = constraintValue;
    [self setNeedsLayout];
}

- (CGFloat)constraintForWidth:(CGFloat)width {
    return self.width - WLAvatarWidth - MAX(WLMinBubbleWidth, width) - 2*WLMessageHorizontalInset;
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
