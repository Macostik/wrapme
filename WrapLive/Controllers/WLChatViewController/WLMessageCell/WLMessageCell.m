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
    __weak typeof(self)weakSelf = self;
	self.avatarView.url = message.contributor.picture.small;
    [self.avatarView setFailure:^(NSError* error) {
        weakSelf.avatarView.image = [UIImage imageNamed:@"default-medium-avatar"];
    }];
    self.nameLabel.text = WLString(message.contributor.name);
	self.timeLabel.text = WLString([message.createdAt stringWithFormat:@"HH:mm"]);
    
    [self.messageTextView determineHyperLink:message.text];
    
    CGSize maxSize = CGSizeMake(WLMaxTextViewWidth, CGFLOAT_MAX);
    CGFloat textWidth = [weakSelf.messageTextView sizeThatFits:maxSize].width;
    if (self.nameLabel) {
        CGFloat nameWidth = [weakSelf.nameLabel sizeThatFits:maxSize].width;
        weakSelf.textViewConstraint.constant = MIN([self constraintForWidth:textWidth], [self constraintForWidth:nameWidth]);
    } else {
        weakSelf.textViewConstraint.constant = [self constraintForWidth:textWidth];
    }
    [weakSelf.messageTextView setNeedsLayout];
}

- (CGFloat)constraintForWidth:(CGFloat)width {
    return self.width - WLAvatarWidth - MAX(WLMinBubbleWidth, width);
}

@end
