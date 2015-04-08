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
#import "WLSoundPlayer.h"
#import "WLProgressBar.h"
#import "WLImageView.h"
#import "WLProgressBar+WLContribution.h"

@interface WLNotificationCell () <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet WLImageView *pictureView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *inWrapLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *textLabel;
@property (weak, nonatomic) IBOutlet WLImageView *wrapImageView;
@property (weak, nonatomic) IBOutlet WLLabel *timeLabel;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;
@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;
@property (weak, nonatomic) IBOutlet WLImageView *avatarImageView;
@property (assign, nonatomic) BOOL isReply;

@end

@implementation WLNotificationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.textLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.pictureView.layer.cornerRadius = self.pictureView.height/2;
    [self.avatarImageView setImageName:@"default-medium-avatar" forState:WLImageViewStateFailed];
}

- (void)setup:(id)entry {
    self.pictureView.url = [entry contributor].picture.small;
    self.timeLabel.text = [entry createdAt].timeAgoStringAtAMPM;
    self.avatarImageView.url = [WLUser currentUser].picture.small;
}

+ (CGFloat)heightCell:(id)entry {
    return [[entry text] heightWithFont:[UIFont preferredFontWithName:WLFontOpenSansRegular
                                                                 preset:WLFontPresetNormal]
                                    width:WLConstants.screenWidth - WLNotificationCommentHorizontalSpacing];
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

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
    [self.entry setUnread:NO];
    [self sendMessageWithText:text];
}

- (void)sendMessageWithText:(NSString *)text {}

@end

@implementation WLMessageNotificationCell

- (void)setup:(WLMessage *)message {
    [super setup:message];
    self.userNameLabel.text = [NSString stringWithFormat:@"%@:", message.contributor.name];
    self.textLabel.text = message.text;
    self.inWrapLabel.text = message.wrap.name;
}

- (void)sendMessageWithText:(NSString *)text {
    if ([self.entry valid]) {
        [[self.entry wrap] uploadMessage:text success:^(WLMessage *message) {
            [WLSoundPlayer playSound:WLSound_s04];
        } failure:^(NSError *error) {
            [error show];
        }];
    }
}

@end

@implementation WLCommentNotificationCell

- (void)setup:(WLComment *)comment {
    [super setup:comment];
    self.userNameLabel.text = [NSString stringWithFormat:@"%@ commented:", comment.contributor.name];
    self.wrapImageView.url = comment.picture.small;
    self.inWrapLabel.text = comment.candy.wrap.name;
    self.textLabel.text = comment.text;
}

- (void)sendMessageWithText:(NSString *)text {
    if ([self.entry valid]) {
        [WLSoundPlayer playSound:WLSound_s04];
        WLComment *comment = [[self.entry candy] uploadComment:[text trim] success:^(WLComment *comment) {
        } failure:^(NSError *error) {
            [error show];
        }];
        [self.progressBar setContribution:comment];
    }
}

@end

@implementation WLCandyNotificationCell

- (void)setup:(WLCandy *)candy {
    [super setup:candy];
    self.userNameLabel.text = [NSString stringWithFormat:@"%@ added a new photo", candy.contributor.name];
    self.wrapImageView.url = candy.picture.small;
    self.inWrapLabel.text = candy.wrap.name;
    self.textLabel.text = nil;
}

+ (CGFloat)heightCell:(id)entry {
    return 22.0;
}

- (void)sendMessageWithText:(NSString *)text {
    if ([self.entry valid]) {
        [WLSoundPlayer playSound:WLSound_s04];
        WLComment *comment = [self.entry uploadComment:[text trim] success:^(WLComment *comment) {
        } failure:^(NSError *error) {
        }];
        [self.progressBar setContribution:comment];
    }
}

@end
