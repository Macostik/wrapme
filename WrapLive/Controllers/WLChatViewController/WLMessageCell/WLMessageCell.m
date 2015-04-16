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

@interface WLMessageCell ()

@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet WLTextView *textView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topTextLabelConstraint;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topAvatarConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *tailView;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImageView;

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
    self.layer.geometryFlipped = YES;
    self.avatarView.hidden = self.nameLabel.hidden = self.dayLabel.hidden = YES;
    [self.avatarView setImageName:@"default-small-avatar" forState:WLImageViewStateEmpty];
    [self.avatarView setImageName:@"default-small-avatar" forState:WLImageViewStateFailed];
    self.textView.textContainerInset = UIEdgeInsetsZero;
    self.textView.textContainer.lineFragmentPadding = .0;
    self.bubbleImageView.image = [WLMessageCell bubbleImageWithColor:self.bubbleImageView.backgroundColor];
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
