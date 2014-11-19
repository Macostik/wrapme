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

@end

@implementation WLMessageCell

- (void)awakeFromNib {
	[super awakeFromNib];
    self.avatarView.hidden = self.nameLabel.hidden = YES;
    self.textLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.bubbleImageView.image = [self.bubbleImageView.image resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
}

- (void)setShowAvatar:(BOOL)showAvatar {
    if (_showAvatar != showAvatar) {
        _showAvatar = showAvatar;
        self.avatarView.hidden = !showAvatar;
    }
}

- (void)setShowName:(BOOL)showName {
    if (_showName != showName) {
        _showName = showName;
        if (self.nameLabel) {
            self.nameLabel.hidden = !showName;
            self.topTextLabelConstraint.constant = showName ? WLMessageNameInset : 0;
        } else {
            self.topTextLabelConstraint.constant = 0;
        }
        [self.textLabel setNeedsLayout];
    }
}

- (void)setShowDay:(BOOL)showDay {
    if (_showDay != showDay) {
        _showDay = showDay;
        self.timeLabel.textColor = showDay ? [UIColor WL_orangeColor] : [UIColor WL_grayColor];
        if (self.timeLabel.x > self.textLabel.superview.x) {
            self.timeLabel.textAlignment = showDay ? NSTextAlignmentRight : NSTextAlignmentLeft;
        } else {
            self.timeLabel.textAlignment = showDay ? NSTextAlignmentLeft : NSTextAlignmentRight;
        }
    }
}

- (void)setup:(WLMessage*)message {
    
    if (self.showAvatar) {
        __weak typeof(self)weakSelf = self;
        self.avatarView.url = message.contributor.picture.small;
        [self.avatarView setFailure:^(NSError* error) {
            weakSelf.avatarView.image = [UIImage imageNamed:@"default-small-avatar"];
        }];
        if (!self.avatarView.url.nonempty) {
            self.avatarView.image = [UIImage imageNamed:@"default-small-avatar"];
        }
    }
    
    if (self.showName) {
        self.nameLabel.text = message.contributor.name;
    }
	
    if (self.showDay) {
        self.timeLabel.text = [message.createdAt stringWithFormat:@"MMM d, yyyy HH:mm"];
    } else {
        self.timeLabel.text = [message.createdAt stringWithFormat:@"HH:mm"];
    }
    
    self.textLabel.text = message.text;
    
    CGSize maxSize = CGSizeMake(WLMaxTextViewWidth, CGFLOAT_MAX);
    CGFloat textWidth = [self.textLabel sizeThatFits:maxSize].width;
    CGFloat constraintValue = [self constraintForWidth:textWidth];
    if (self.showName) {
        CGFloat nameWidth = [self.nameLabel sizeThatFits:maxSize].width;
        constraintValue = MIN(constraintValue, [self constraintForWidth:nameWidth]);
    }
    if (self.textViewConstraint.constant != constraintValue) {
        self.textViewConstraint.constant = constraintValue;
        [self.textLabel.superview setNeedsLayout];
    }
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
