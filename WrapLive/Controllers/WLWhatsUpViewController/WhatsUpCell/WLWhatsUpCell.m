//
//  WLWhatsUpCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWhatsUpCell.h"
#import "UILabel+Additions.h"
#import "UITextView+Aditions.h"
#import "UIFont+CustomFonts.h"
#import "TTTAttributedLabel.h"
#import "WLComposeBar.h"
#import "WLSoundPlayer.h"
#import "WLProgressBar.h"
#import "WLCircleImageView.h"
#import "WLProgressBar+WLContribution.h"
#import "NSString+Additions.h"
#import "WLIconButton.h"
#import "WLTextView.h"
#import "WLFontPresetter.h"
#import "WLWhatsUpEvent.h"

@interface WLWhatsUpCell ()

@property (weak, nonatomic) IBOutlet WLCircleImageView *pictureView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *inWrapLabel;
@property (weak, nonatomic) IBOutlet WLTextView *textView;
@property (weak, nonatomic) IBOutlet WLImageView *wrapImageView;
@property (weak, nonatomic) IBOutlet WLLabel *timeLabel;

@end

@implementation WLWhatsUpCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.textView.textContainerInset = UIEdgeInsetsZero;
    self.textView.textContainer.lineFragmentPadding = .0;
}

- (void)setup:(WLWhatsUpEvent*)event {
    WLContribution *contribution = event.contribution;
    [contribution markAsRead];
    self.pictureView.url = contribution.contributor.picture.small;
    self.timeLabel.text = event.date.timeAgoStringAtAMPM;
    self.wrapImageView.url = contribution.picture.small;
}

+ (CGFloat)additionalHeightCell:(WLWhatsUpEvent *)event {
    if (![event.contribution respondsToSelector:@selector(text)]) return .0f;
    UIFont *font = [UIFont preferredFontWithName:WLFontOpenSansRegular preset:WLFontPresetNormal];
    return [[event.contribution text] heightWithFont:font width:WLConstants.screenWidth - WLWhatsUpCommentHorizontalSpacing];
}

@end

@implementation WLCommentWhatsUpCell

- (void)setup:(WLWhatsUpEvent*)event {
    [super setup:event];
    WLComment *comment = event.contribution;
    self.userNameLabel.text = [NSString stringWithFormat:@"%@:", comment.contributor.name];
    self.inWrapLabel.text = comment.candy.wrap.name;
    [self.textView determineHyperLink:comment.text];
}

@end

@implementation WLCandyWhatsUpCell

- (void)setup:(WLWhatsUpEvent*)event {
    [super setup:event];
    WLCandy *candy = event.contribution;
    if (event.event == WLEventUpdate) {
        self.userNameLabel.text = [NSString stringWithFormat:WLLS(@"Edited by %@"), candy.editor.name];
    } else {
        self.userNameLabel.text = [NSString stringWithFormat:WLLS(@"Photo by %@"), candy.contributor.name];
    }
    self.inWrapLabel.text = candy.wrap.name;
    self.textView.text = nil;
}

@end
