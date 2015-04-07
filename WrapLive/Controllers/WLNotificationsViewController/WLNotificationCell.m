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
#import "WLComposeBar.h"

@interface WLNotificationCell () <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet WLImageView *pictureView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *inWrapLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *textLabel;
@property (weak, nonatomic) IBOutlet WLImageView *wrapImageView;
@property (weak, nonatomic) IBOutlet WLLabel *timeLabel;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;
@property (assign, nonatomic) BOOL isReply;

@end

@implementation WLNotificationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.textLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.pictureView.layer.cornerRadius = self.pictureView.height/2;
}



#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (IBAction)retryMessage:(UIButton *)sender {
    self.composeBar.hidden = !self.composeBar.hidden;
    if ([self.delegate respondsToSelector:@selector(notificationCell:didRetryMessageThroughComposeBar:)]) {
        [self.delegate notificationCell:self didRetryMessageThroughComposeBar:self.composeBar];
    }
}

@end

@implementation WLMessageNotificationCell

- (void)setup:(WLMessage *)message {
    self.pictureView.url = message.contributor.picture.small;
    self.userNameLabel.text = message.contributor.name;
    self.textLabel.text = message.text;
    self.inWrapLabel.text = message.wrap.name;
    self.timeLabel.text = message.createdAt.timeAgoStringAtAMPM;
}

@end

@implementation WLCandyNotificationCell

- (void)setup:(id)entry {
    if ([entry isKindOfClass:[WLCandy class]]) {
        self.pictureView.url = [entry contributor].picture.small;
        self.wrapImageView.url = [entry picture].small;
        self.userNameLabel.text = [entry contributor].name;
        self.inWrapLabel.text = [entry wrap].name;
        self.timeLabel.text = [entry createdAt].timeAgoStringAtAMPM;
    } else {
        self.pictureView.url = [entry contributor].picture.small;
        self.wrapImageView.url = [entry picture].small;
        self.userNameLabel.text = [entry contributor].name;
        self.inWrapLabel.text = [entry candy].wrap.name;
        self.timeLabel.text = [entry createdAt].timeAgoStringAtAMPM;
        self.textLabel.text = [entry text];
    }
   
}

@end
