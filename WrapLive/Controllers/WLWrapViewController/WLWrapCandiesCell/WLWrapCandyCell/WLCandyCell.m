//
//  WLWrapCandyCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandyCell.h"
#import "WLImageFetcher.h"
#import "WLEntryNotifier.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "NSString+Additions.h"
#import "UIView+GestureRecognizing.h"
#import "UIView+QuatzCoreAnimations.h"
#import "UIView+Shorthand.h"
#import "WLToast.h"
#import "WLImageFetcher.h"
#import "MFMailComposeViewController+Additions.h"
#import "WLUploading.h"
#import "WLUser.h"
#import "WLAPIManager.h"
#import "WLEntryManager.h"
#import "WLMenu.h"

@interface WLCandyCell () <WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet WLImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;

@property (strong, nonatomic) WLMenu* menu;

@end

@implementation WLCandyCell

- (void)awakeFromNib {
	[super awakeFromNib];
    self.coverView.placeholderName = @"ic_photo_placeholder";
	[[WLCandy notifier] addReceiver:self];
    __weak typeof(self)weakSelf = self;
    if (self.userInteractionEnabled) {
        self.menu = [WLMenu menuWithView:self configuration:^BOOL (WLMenu *menu) {
            WLCandy* candy = weakSelf.entry;
            if (candy.deletable) {
                [menu addDeleteItem:^{
                    weakSelf.userInteractionEnabled = NO;
                    [candy remove:^(id object) {
                        weakSelf.userInteractionEnabled = YES;
                    } failure:^(NSError *error) {
                        [error show];
                        weakSelf.userInteractionEnabled = YES;
                    }];
                }];
            } else {
                [menu addReportItem:^{
                    [MFMailComposeViewController messageWithCandy:candy];
                }];
            }
            [menu addDownloadItem:^{
                [candy download:^{
                } failure:^(NSError *error) {
                    [error show];
                }];
                [WLToast showPhotoDownloadingMessage];
            }];
            return YES;
        }];
        self.menu.vibrate = YES;
    }
    
    [self.contentView setFullFlexible];
}

- (void)setup:(WLCandy*)candy {
	self.userInteractionEnabled = YES;
    if (self.commentLabel) {
        WLComment* comment = [candy.comments lastObject];
        self.commentLabel.text = comment.text;
        self.commentLabel.hidden = !self.commentLabel.text.nonempty;
    }
	self.coverView.animatingPicture = candy.picture;
    self.coverView.url = candy.picture.small;
}

- (void)select:(WLCandy*)candy {
    if (candy.valid) {
        [super select:candy];
    }
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier candyUpdated:(WLCandy *)candy {
	[self resetup];
}

- (WLCandy *)notifierPreferredCandy:(WLEntryNotifier *)notifier {
    return self.entry;
}

@end
