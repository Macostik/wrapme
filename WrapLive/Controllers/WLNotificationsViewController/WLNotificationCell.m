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
#import "NSString+Additions.h"
#import "WLIconButton.h"
#import "WLTextView.h"

@interface WLNotificationCell () <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet WLImageView *pictureView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *inWrapLabel;
@property (weak, nonatomic) IBOutlet WLTextView *textView;
@property (weak, nonatomic) IBOutlet WLImageView *wrapImageView;
@property (weak, nonatomic) IBOutlet WLLabel *timeLabel;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;
@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;
@property (weak, nonatomic) IBOutlet WLImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet WLIconButton *retryButton;
@property (weak, nonatomic) IBOutlet WLButton *sendButton;
@property (weak, nonatomic) IBOutlet WLTextView *containerTextView;
@property (assign, nonatomic) BOOL isBorderAvatar;
@property (strong, nonatomic) id storedEntry;

@end

@implementation WLNotificationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.containerTextView.textContainerInset = self.textView.textContainerInset = UIEdgeInsetsZero;
    self.pictureView.layer.cornerRadius = self.pictureView.height/2;
    [self.avatarImageView setImageName:@"default-medium-avatar" forState:WLImageViewStateFailed];
}

- (void)setup:(id)entry {
    self.pictureView.url = [entry contributor].picture.small;
    self.timeLabel.text = [entry createdAt].timeAgoStringAtAMPM;
    self.avatarImageView.url = [WLUser currentUser].picture.small;
    
    if ([self.delegate respondsToSelector:@selector(notificationCell:createdEntry:)]) {
       self.storedEntry = [self.delegate notificationCell:self createdEntry:entry];
    }
    
    self.containerTextView.hidden = self.avatarImageView.hidden = self.storedEntry == nil;
    self.retryButton.hidden = self.composeBar.hidden = !(self.storedEntry == nil);
    [self.containerTextView determineHyperLink:[self.storedEntry text]];
    __weak __typeof(self)weakSelf = self;
    [self.progressBar setContribution:self.storedEntry isHideProgress:NO complition:^(BOOL flag) {
        weakSelf.isBorderAvatar = !(weakSelf.storedEntry == nil);
    }];
}

- (void)setIsBorderAvatar:(BOOL)isBorderAvatar {
      WLImageView *avatarImageView = _avatarImageView;
    if (isBorderAvatar) {
        avatarImageView.layer.borderColor = [UIColor WL_orangeColor].CGColor;
        avatarImageView.layer.borderWidth = 2.0f;
    } else {
         avatarImageView.layer.borderWidth = .0f;
    }
}

+ (CGFloat)heightCell:(id)entry {
    UIFont *font = [UIFont preferredFontWithName:WLFontOpenSansRegular
                                          preset:WLFontPresetNormal];
    return WLCalculateHeightString([entry text], font, WLConstants.screenWidth - WLNotificationCommentHorizontalSpacing);
}

- (IBAction)retryMessage:(UIButton *)sender {
    self.avatarImageView.hidden = self.progressBar.hidden = YES;
    if ([self.delegate respondsToSelector:@selector(notificationCell:didRetryMessageByComposeBar:)]) {
        [self.delegate notificationCell:self didRetryMessageByComposeBar:self.composeBar];
    }
}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
    [self.entry setUnread:NO];
    [self sendMessageWithText:text];
    if ([self.delegate respondsToSelector:@selector(notificationCell:calculateHeightTextView:)]) {
        UIFont *font = [UIFont preferredFontWithName:WLFontOpenSansLight preset:WLFontPresetSmall];
        CGFloat height = WLCalculateHeightString(text, font, self.containerTextView.width);
        [self.delegate notificationCell:self calculateHeightTextView:height];
    }
}

- (void)composeBarDidChangeHeight:(WLComposeBar *)composeBar {
    if ([self.delegate respondsToSelector:@selector(notificationCell:didChangeHeightComposeBar:)]) {
        [self.delegate notificationCell:self didChangeHeightComposeBar:composeBar];
    }
}

- (void)composeBarDidBeginEditing:(WLComposeBar*)composeBar {
    if ([self.delegate respondsToSelector:@selector(notificationCell:beginEditingComposaBar:)]) {
        [self.delegate notificationCell:self beginEditingComposaBar:composeBar];
    }
}

- (void)sendMessageWithText:(NSString *)text {}

@end

@implementation WLMessageNotificationCell

- (void)setup:(WLMessage *)message {
    [super setup:message];
    self.userNameLabel.text = [NSString stringWithFormat:@"%@:", message.contributor.name];
    self.inWrapLabel.text = message.wrap.name;
    [self.textView determineHyperLink:message.text];
}

- (void)sendMessageWithText:(NSString *)text {
    self.retryButton.hidden = YES;
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
    [self.textView determineHyperLink:comment.text];
}

- (void)sendMessageWithText:(NSString *)text {
    if ([self.entry valid]) {
        [WLSoundPlayer playSound:WLSound_s04];
        id entry = [[self.entry candy] uploadComment:[text trim] success:^(WLComment *comment) {
        } failure:^(NSError *error) {
            [error show];
        }];
        if ([self.delegate respondsToSelector:@selector(notificationCell:createEntry:)]) {
            [self.delegate notificationCell:self createEntry:entry];
        }
    }
}

@end

@implementation WLCandyNotificationCell

+ (CGFloat)heightCell:(id)entry {
    return 12.0;
}

- (void)setup:(WLCandy *)candy {
    [super setup:candy];
    self.userNameLabel.text = [NSString stringWithFormat:@"%@ added a new photo", candy.contributor.name];
    self.wrapImageView.url = candy.picture.small;
    self.inWrapLabel.text = candy.wrap.name;
    self.textView.text = nil;
}

- (void)sendMessageWithText:(NSString *)text {
    if ([self.entry valid]) {
        [WLSoundPlayer playSound:WLSound_s04];
        id entry = [self.entry uploadComment:[text trim] success:^(WLComment *comment) {
        } failure:^(NSError *error) {
        }];
        if ([self.delegate respondsToSelector:@selector(notificationCell:createEntry:)]) {
            [self.delegate notificationCell:self createEntry:entry];
        }
    }
}

@end
