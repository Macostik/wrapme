//
//  WLNotificationCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationCell.h"
#import "UILabel+Additions.h"
#import "UITextView+Aditions.h"
#import "UIFont+CustomFonts.h"
#import "TTTAttributedLabel.h"

@interface WLNotificationCell () <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet WLImageView *pictureView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *inWrapLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *commentLabel;
@property (weak, nonatomic) IBOutlet WLImageView *wrapImageView;
@property (weak, nonatomic) IBOutlet WLLabel *timeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *composeBarHeightConstrain;
@property (assign, nonatomic) BOOL isReply;

@end

@implementation WLNotificationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.commentLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.pictureView.layer.cornerRadius = self.pictureView.height/2;
//    self.composeBarHeightConstrain.constant = 0.0;
}

- (void)setup:(WLComment*)comment {
    self.pictureView.url = comment.contributor.picture.small;
    self.wrapImageView.url = comment.candy.picture.small;
    self.userNameLabel.text = comment.contributor.name;
    self.commentLabel.text = comment.text;
    self.inWrapLabel.text = comment.candy.wrap.name;
    self.timeLabel.text = comment.createdAt.timeAgoStringAtAMPM;
    
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (IBAction)retryMessage:(UIButton *)sender {
    [UIView performWithoutAnimation:^{
        self.composeBarHeightConstrain.constant = self.isReply != self.isReply ? 40 : 0;
        [self layoutIfNeeded];
    }];
}

@end
