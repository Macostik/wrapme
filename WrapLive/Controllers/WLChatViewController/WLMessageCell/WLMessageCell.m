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

@interface WLMessageCell ()

@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImageView;
@property (strong, nonatomic) NSArray *bubbleImages;
@end

@implementation WLMessageCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.avatarView.circled = YES;
    
    self.bubbleImages = @[[[UIImage imageNamed:@"gray_Bubble"] resizableImageWithCapInsets:UIEdgeInsetsMake(WLPadding, WLPadding, WLBottomIdent, 18)],
                          [[UIImage imageNamed:@"red_Bubble"] resizableImageWithCapInsets:UIEdgeInsetsMake(WLPadding, 18, WLBottomIdent, WLPadding)]];
}

- (void)setupItemData:(WLCandy*)candy {
	self.avatarView.url = candy.contributor.picture.medium;
	self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", WLString(candy.contributor.name), WLString([candy.createdAt stringWithFormat:@"HH:mm"])];
	self.messageLabel.text = candy.message;
	__weak typeof(self)weakSelf = self;
	[UIView performWithoutAnimation:^{
        weakSelf.messageLabel.size = CGSizeLargerSize([weakSelf.messageLabel sizeThatFits:CGSizeMake(250, CGFLOAT_MAX)],
                                                      (CGSize){WLMinBubbleWidth, weakSelf.messageLabel.height});
        if (weakSelf.avatarView.x > weakSelf.messageLabel.x) {
            weakSelf.messageLabel.x = weakSelf.avatarView.x - weakSelf.messageLabel.width - WLMessageAuthorLabelHeight/2;
        }
	}];
    [self drawMessageBubbleForCandy:candy];
}

- (void)drawMessageBubbleForCandy:(WLCandy *)candy {
    self.bubbleImageView.image = self.bubbleImages[![candy.contributor isCurrentUser]];
    self.bubbleImageView.frame = self.messageLabel.frame;
    self.bubbleImageView.x -= WLPadding;
    self.bubbleImageView.height += 10;
    self.bubbleImageView.width += 2*WLPadding;
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
}

@end
