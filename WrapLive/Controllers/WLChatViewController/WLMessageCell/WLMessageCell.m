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

@interface WLMessageCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewConstraint;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation WLMessageCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.avatarView.circled = YES;
    self.messageTextView.textContainerInset = self.nameLabel ? UIEdgeInsetsMake(14, -5, 0, -5) : UIEdgeInsetsMake(0, -5, 0, -5);
}

- (void)setup:(WLMessage*)message {
    
    if (self.avatarView) {
        __weak typeof(self)weakSelf = self;
        self.avatarView.url = message.contributor.picture.small;
        [self.avatarView setFailure:^(NSError* error) {
            weakSelf.avatarView.image = [UIImage imageNamed:@"default-medium-avatar"];
        }];
    }
    
    if (self.nameLabel) {
        self.nameLabel.text = message.contributor.name;
    }
	self.timeLabel.text = [message.createdAt stringWithFormat:@"HH:mm"];
    
    self.messageTextView.text = message.text;
    
    CGSize maxSize = CGSizeMake(WLMaxTextViewWidth, CGFLOAT_MAX);
    CGFloat textWidth = [self.messageTextView sizeThatFits:maxSize].width;
    CGFloat constraintValue = [self constraintForWidth:textWidth];
    if (self.nameLabel) {
        CGFloat nameWidth = [self.nameLabel sizeThatFits:maxSize].width;
        constraintValue = MIN(constraintValue, [self constraintForWidth:nameWidth]);
    }
    if (self.textViewConstraint.constant != constraintValue) {
        self.textViewConstraint.constant = constraintValue;
        [self.messageTextView setNeedsLayout];
    }
}

- (CGFloat)constraintForWidth:(CGFloat)width {
    return self.width - WLAvatarWidth - MAX(WLMinBubbleWidth, width);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.messageTextView.text = nil;
}

@end
