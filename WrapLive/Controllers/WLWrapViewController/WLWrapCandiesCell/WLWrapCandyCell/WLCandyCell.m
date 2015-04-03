//
//  WLWrapCandyCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandyCell.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "UIView+GestureRecognizing.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLToast.h"
#import "MFMailComposeViewController+Additions.h"
#import "WLMenu.h"
#import "UIFont+CustomFonts.h"

@interface WLCandyCell () <WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet WLImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;


@end

@implementation WLCandyCell

- (void)awakeFromNib {
	[super awakeFromNib];
    [self.coverView setContentMode:UIViewContentModeCenter forState:WLImageViewStateFailed];
    [self.coverView setContentMode:UIViewContentModeCenter forState:WLImageViewStateEmpty];
    [self.coverView setImageName:@"ic_photo_placeholder" forState:WLImageViewStateFailed];
    [self.coverView setImageName:@"ic_photo_placeholder" forState:WLImageViewStateEmpty];
    
	[[WLCandy notifier] addReceiver:self];
    __weak typeof(self)weakSelf = self;
    if (!self.disableMenu) {
        [[WLMenu sharedMenu] addView:self configuration:^(WLMenu *menu, BOOL *vibrate) {
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
        }];
    }
}

- (void)setup:(WLCandy*)candy {
	self.userInteractionEnabled = YES;
    if (self.commentLabel) {
        WLComment* comment = [[candy sortedComments] firstObject];
        self.commentLabel.text = comment.text;
        self.commentLabel.superview.hidden = !self.commentLabel.text.nonempty;
    }
	self.coverView.animatingPicture = candy.picture;
    self.coverView.url = candy.picture.small;

    [[WLMenu sharedMenu] hide];
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
