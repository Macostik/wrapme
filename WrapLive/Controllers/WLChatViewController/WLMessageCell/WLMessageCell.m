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
#import "WLTextView.h"

@interface WLMessageCell ()

@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLTextView *textView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topTextLabelConstraint;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topAvatarConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *leftBubble;
@property (weak, nonatomic) IBOutlet UIImageView *rightBubble;
@property (weak, nonatomic) IBOutlet UIImageView *tailView;

@end

@implementation WLMessageCell

- (void)awakeFromNib {
	[super awakeFromNib];
    self.layer.geometryFlipped = YES;
    self.avatarView.hidden = self.nameLabel.hidden = self.dayLabel.hidden = YES;
    self.leftBubble.image = [self.leftBubble.image resizableImageWithCapInsets:UIEdgeInsetsMake(5, 0, 5, 0) resizingMode:UIImageResizingModeStretch];
    self.rightBubble.image = [self.rightBubble.image resizableImageWithCapInsets:UIEdgeInsetsMake(5, 0, 5, 0) resizingMode:UIImageResizingModeStretch];
    [self.avatarView setImageName:@"default-small-avatar" forState:WLImageViewStateEmpty];
    [self.avatarView setImageName:@"default-small-avatar" forState:WLImageViewStateFailed];
    self.textView.textContainerInset = UIEdgeInsetsZero;
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
    self.avatarView.hidden = self.nameLabel.hidden = self.tailView.hidden = !showName;
    self.topTextLabelConstraint.constant = showName ? WLMessageNameInset : 0;
}

- (void)setup:(WLMessage*)message {
    
    if (_showName) {
        self.avatarView.url = message.contributor.picture.small;
        self.nameLabel.text = message.contributedByCurrentUser ? WLLS(@"You") : message.contributor.name;
    }
	
    self.timeLabel.text = [message.createdAt stringWithFormat:@"h:mmaa"];
    if (_showDay) {
        self.dayLabel.text = [message.createdAt stringWithFormat:@"MMM d, yyyy"];
    }
    
    [self.textView determineHyperLink:message.text];
}

@end
