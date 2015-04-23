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

- (void)setup:(id)entry {
    self.pictureView.url = [entry contributor].picture.small;
    self.timeLabel.text = [entry createdAt].timeAgoStringAtAMPM;
    self.wrapImageView.url = [entry picture].small;
}

+ (CGFloat)additionalHeightCell:(id)entry {
    if (![entry respondsToSelector:@selector(text)]) return .0f;
    UIFont *font = [UIFont preferredFontWithName:WLFontOpenSansRegular
                                          preset:WLFontPresetLarge];
    return WLCalculateHeightString([entry text], font, WLConstants.screenWidth - WLWhatsUpCommentHorizontalSpacing);
}

@end

@implementation WLCommentWhatsUpCell

- (void)setup:(WLComment *)comment {
    [super setup:comment];
    self.userNameLabel.text = [NSString stringWithFormat:@"%@:", comment.contributor.name];
    self.inWrapLabel.text = comment.candy.wrap.name;
    [self.textView determineHyperLink:comment.text];
}

@end

@implementation WLCandyWhatsUpCell

- (void)setup:(WLCandy *)candy {
    [super setup:candy];
    self.userNameLabel.text = [NSString stringWithFormat:WLLS(@"Photo by %@"), candy.contributor.name];
    self.inWrapLabel.text = candy.wrap.name;
    self.textView.text = nil;
}

@end
