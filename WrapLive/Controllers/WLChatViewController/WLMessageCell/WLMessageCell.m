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
#import "WLSupportFunctions.h"
#import "UITextView+Aditions.h"
#import "UIFont+CustomFonts.h"
#import "WLAPIRequest.h"

@interface WLMessageCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewConstraint;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImageView;

@end

@protocol WLChatMessage <NSObject>

@property (nonatomic, readonly) WLUser* contributor;

@property (nonatomic, readonly) NSString* text;

@property (nonatomic, readonly) NSDate* displayDate;

@end

@interface WLMessage (WLChatMessage) <WLChatMessage> @end

@implementation WLMessage (WLChatMessage)

- (NSDate *)displayDate {
    return self.createdAt;
}

@end

@interface WLUser (WLChatMessage) <WLChatMessage> @end

@implementation WLUser (WLChatMessage)

- (WLUser *)contributor {
    return self;
}

- (NSString *)text {
    return @"Is typing ...";
}

- (NSDate *)displayDate {
    return [NSDate now];
}

@end

@implementation WLMessageCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.avatarView.circled = YES;
}

- (void)setupItemData:(id <WLChatMessage>)message {
    __weak typeof(self)weakSelf = self;
    self.messageTextView.textContainerInset = [self.reuseIdentifier isEqualToString:@"WLMyBubbleMessageCell"] || [self.reuseIdentifier isEqualToString:@"WLBubbleMessageCell"] ? UIEdgeInsetsMake(0, -5, 0, -5) : UIEdgeInsetsMake(14, -5, 0, -5);
	self.avatarView.url = message.contributor.picture.medium;
    [self.avatarView setFailure:^(NSError* error) {
        weakSelf.avatarView.image = [UIImage imageNamed:@"default-medium-avatar"];
    }];
    self.nameLabel.text = [NSString stringWithFormat:@"%@", WLString(message.contributor.name)];
	self.timeLabel.text = [NSString stringWithFormat:@"%@", WLString([message.displayDate stringWithFormat:@"HH:mm"])];;
    [self.messageTextView determineHyperLink:message.text withFont:[UIFont lightFontOfSize:15.0f]];
	[UIView performWithoutAnimation:^{
        CGSize sizeNameLabel = [weakSelf.nameLabel sizeThatFits:CGSizeMake(50, CGFLOAT_MAX)];
        CGSize size = [weakSelf.messageTextView sizeThatFits:CGSizeMake(WLMaxTextViewWidth, CGFLOAT_MAX)];
        weakSelf.textViewConstraint.constant = MAX (weakSelf.width - 66 - MAX(WLMinBubbleWidth, size.width), 65);
        [weakSelf.messageTextView layoutIfNeeded];
	}];
}

@end
