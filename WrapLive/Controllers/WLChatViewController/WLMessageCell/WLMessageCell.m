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
#import "WLServerTime.h"
#import "UITextView+Aditions.h"
#import "UIFont+CustomFonts.h"

@interface WLMessageCell ()

@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImageView;
@property (strong, nonatomic) NSArray *bubbleImages;
@end

@protocol WLChatMessage <NSObject>

@property (nonatomic, strong) WLUser* contributor;

@property (nonatomic, strong) NSString* text;

@property (nonatomic, strong) NSDate* createdAt;

@end

@interface WLUser (WLChatMessage) <WLChatMessage>

@end

@implementation WLUser (WLChatMessage)

@dynamic contributor;
@dynamic text;

- (WLUser *)contributor {
    return self;
}

- (NSString *)text {
    return @"...";
}

- (NSDate *)createdAt {
    return [WLServerTime current];
}

- (NSDate *)updatedAt {
    return [WLServerTime current];
}

@end

@implementation WLMessageCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.avatarView.circled = YES;
    self.bubbleImages = @[[[UIImage imageNamed:@"gray_Bubble"] resizableImageWithCapInsets:UIEdgeInsetsMake(WLPadding, WLPadding, WLBottomIdent, 18)],
                          [[UIImage imageNamed:@"red_Bubble"] resizableImageWithCapInsets:UIEdgeInsetsMake(WLPadding, 18, WLBottomIdent, WLPadding)]];
}

- (void)setupItemData:(id <WLChatMessage>)message {
    __weak typeof(self)weakSelf = self;
	self.avatarView.url = message.contributor.picture.medium;
    [self.avatarView setFailure:^(NSError* error) {
        weakSelf.avatarView.image = [UIImage imageNamed:@"default-medium-avatar"];
    }];
	self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", WLString(message.contributor.name), WLString([message.createdAt stringWithFormat:@"HH:mm"])];
    [self.messageTextView determineHyperLink:message.text withFont:[UIFont lightFontOfSize:15.0f]];
    self.messageTextView.textContainerInset = UIEdgeInsetsMake(0, -5, 0, -5);
	[UIView performWithoutAnimation:^{
        CGSize size = [weakSelf.messageTextView sizeThatFits:CGSizeMake(250, CGFLOAT_MAX)];
        weakSelf.messageTextView.size = CGSizeMake(MAX(WLMinBubbleWidth, size.width), size.height);
        if (weakSelf.avatarView.x > weakSelf.messageTextView.x) {
            weakSelf.messageTextView.x = weakSelf.avatarView.x - weakSelf.messageTextView.width - WLMessageAuthorLabelHeight/2;
        }
	}];
    [self drawMessageBubbleForCandy:message];
    self.bubbleImageView.hidden = !message.text.nonempty;
}

- (void)drawMessageBubbleForCandy:(WLCandy *)candy {
    self.bubbleImageView.image = self.bubbleImages[![candy.contributor isCurrentUser]];
    self.bubbleImageView.frame = self.messageTextView.frame;
    self.bubbleImageView.x -= WLPadding;
    self.bubbleImageView.height += 10;
    self.bubbleImageView.width += 2*WLPadding;
}

@end
