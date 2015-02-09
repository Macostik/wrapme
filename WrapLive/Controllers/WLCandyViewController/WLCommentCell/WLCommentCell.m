//
//  WLCommentCell.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCommentCell.h"
#import "WLImageFetcher.h"
#import "UIView+Shorthand.h"
#import "UIFont+CustomFonts.h"
#import "UILabel+Additions.h"
#import "NSDate+Additions.h"
#import "UIAlertView+Blocks.h"
#import "WLAPIManager.h"
#import "WLEntryNotifier.h"
#import "UIActionSheet+Blocks.h"
#import "UIView+GestureRecognizing.h"
#import "WLToast.h"
#import "WLEntryManager.h"
#import "WLMenu.h"
#import "NSString+Additions.h"
#import "WLProgressBar+WLContribution.h"
#import "WLNetwork.h"
#import "UITextView+Aditions.h"
#import "UIFont+CustomFonts.h"
#import "UIColor+CustomColors.h"
#import "TTTAttributedLabel.h"
#import "UIImage+Drawing.h"

@interface WLCommentCell () <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet WLImageView *authorImageView;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) WLProgressBar *progressBar;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *textLabel;

@end

@implementation WLCommentCell

- (void)awakeFromNib {
	[super awakeFromNib];
    __weak typeof(self)weakSelf = self;
    
    [self.authorImageView setImageName:@"default-medium-avatar" forState:WLImageViewStateEmpty];
    [self.authorImageView setImageName:@"default-medium-avatar" forState:WLImageViewStateFailed];
    
    [[WLMenu sharedMenu] addView:self configuration:^void (WLMenu *menu, BOOL *vibrate) {
        WLComment* comment = weakSelf.entry;
        if (comment.deletable) {
            [menu addDeleteItem:^{
                weakSelf.userInteractionEnabled = NO;
                [weakSelf.entry remove:^(id object) {
                    weakSelf.userInteractionEnabled = YES;
                } failure:^(NSError *error) {
                    [error show];
                    weakSelf.userInteractionEnabled = YES;
                }];
            }];
        } else {
            *vibrate = NO;
            [WLToast showWithMessage:WLLS(@"Cannot delete comment not posted by you.")];
        }
    }];
    self.textLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
}

- (void)setEntry:(id)entry {
    if (self.entry != entry) {
        self.progressBar = nil;
    }
    [super setEntry:entry];
}

- (void)setup:(WLComment *)entry {
	self.userInteractionEnabled = YES;
    if (entry.unread) entry.unread = NO;
	self.authorNameLabel.text = entry.contributor.name;
    self.textLabel.text = entry.text;
	self.authorImageView.url = entry.contributor.picture.small;
    self.dateLabel.text = entry.createdAt.timeAgoString;
    
    if (entry.status != WLContributionStatusUploaded) {
        WLUploadingData* uploadingData = entry.uploading.data;
        WLProgressBar* progressBar = (id)uploadingData.progressBar;
        if (!progressBar) {
            uploadingData.progressBar = progressBar = [[WLProgressBar alloc] initWithFrame:self.authorImageView.frame];
        }
        self.progressBar = progressBar;
        progressBar.delegate = self.delegate;
    }
}

- (void)setProgressBar:(WLProgressBar *)progressBar {
    if (progressBar != _progressBar) {
        [_progressBar removeFromSuperview];
        if (progressBar) {
            [self.authorImageView.superview addSubview:progressBar];
        }
        _progressBar = progressBar;
    }
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
