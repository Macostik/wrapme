//
//  WLNotificationCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationCell.h"
#import "WLNotification.h"
#import "WLImageFetcher.h"
#import "WLUser+Extended.h"
#import "NSDate+Additions.h"
#import "UILabel+Additions.h"
#import "WLEntryManager.h"
#import "UIView+Shorthand.h"
#import "UITextView+Aditions.h"
#import "UIFont+CustomFonts.h"
#import "TTTAttributedLabel.h"

@interface WLNotificationCell () <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet WLImageView *pictureView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *inWrapLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *commentTextView;
@property (weak, nonatomic) IBOutlet WLImageView *wrapImageView;

@end

@implementation WLNotificationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.commentTextView.enabledTextCheckingTypes = NSTextCheckingTypeLink;
}

- (void)setup:(WLComment*)comment {
    self.pictureView.url = comment.contributor.picture.small;
    self.wrapImageView.url = comment.candy.picture.small;
    self.userNameLabel.text = [NSString stringWithFormat:@"%@  %@",comment.contributor.name, comment.createdAt.timeAgoString];
    self.commentTextView.text = [NSString stringWithFormat:@"\"%@\"", comment.text];
    self.inWrapLabel.text = [NSString stringWithFormat:@"in Wrap: \"%@\"", comment.candy.wrap.name];
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
