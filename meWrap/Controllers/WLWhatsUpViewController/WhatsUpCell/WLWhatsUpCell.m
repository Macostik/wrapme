//
//  WLWhatsUpCell.m
//  meWrap
//
//  Created by Ravenpod on 8/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWhatsUpCell.h"
#import "WLLabel.h"
#import "WLComposeBar.h"
#import "WLSoundPlayer.h"
#import "WLProgressBar.h"
#import "WLCircleImageView.h"
#import "WLProgressBar+WLContribution.h"
#import "WLFontPresetter.h"
#import "WLWhatsUpEvent.h"

@interface WLWhatsUpCell ()

@property (weak, nonatomic) IBOutlet WLCircleImageView *pictureView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *inWrapLabel;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet WLImageView *wrapImageView;
@property (weak, nonatomic) IBOutlet WLLabel *timeLabel;

@end

@implementation WLWhatsUpCell

- (void)setup:(WLWhatsUpEvent*)event {
    Contribution *contribution = event.contribution;
    [contribution markAsRead];
    self.timeLabel.text = event.date.timeAgoStringAtAMPM;
    self.wrapImageView.url = contribution.picture.small;
}

@end

@implementation WLCommentWhatsUpCell

- (void)setup:(WLWhatsUpEvent*)event {
    [super setup:event];
    Comment *comment = event.contribution;
    self.pictureView.url = comment.contributor.picture.small;
    self.userNameLabel.text = [NSString stringWithFormat:@"%@:", comment.contributor.name];
    self.inWrapLabel.text = comment.candy.wrap.name;
    self.textView.text = comment.text;
}

@end

@implementation WLCandyWhatsUpCell

- (void)setup:(WLWhatsUpEvent*)event {
    [super setup:event];
    Candy *candy = event.contribution;
    if (event.event == WLEventUpdate) {
        self.pictureView.url = candy.editor.picture.small;
        self.userNameLabel.text = [NSString stringWithFormat:@"formatted_edited_by".ls, candy.editor.name];
    } else {
        self.pictureView.url = candy.contributor.picture.small;
        self.userNameLabel.text = [NSString stringWithFormat:(candy.isVideo ? @"formatted_video_by" : @"formatted_photo_by").ls, candy.contributor.name];
    }
    self.inWrapLabel.text = candy.wrap.name;
    self.textView.text = nil;
}

@end
