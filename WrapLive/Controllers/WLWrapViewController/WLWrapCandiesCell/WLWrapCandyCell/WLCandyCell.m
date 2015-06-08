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
#import "WLChronologicalEntryPresenter.h"
#import "WLDownloadingView.h"
#import "WLUploadPhotoViewController.h"

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
            
            if (candy.status != WLContributionStatusInProgress) {
                [menu addEditPhotoItem:^(WLCandy *candy) {
                    [WLDownloadingView downloadAndEditCandy:candy success:^(UIImage *image) {
                    } failure:^(NSError *error) {
                        [error show];
                    }];
                }];
            }
            
            [menu addDownloadItem:^(WLCandy *candy) {
                [candy download:^{
                    [WLToast showPhotoDownloadingMessage];
                } failure:^(NSError *error) {
                    [error show];
                }];
            }];
            
            if (candy.deletable) {
                [menu addDeleteItem:^(WLCandy *candy) {
                    weakSelf.userInteractionEnabled = NO;
                    [candy remove:^(id object) {
                        weakSelf.userInteractionEnabled = YES;
                    } failure:^(NSError *error) {
                        [error show];
                        weakSelf.userInteractionEnabled = YES;
                    }];
                }];
            } else {
                [menu addReportItem:^(WLCandy *candy) {
                    [MFMailComposeViewController messageWithCandy:candy];
                }];
            }
            
            return candy;
        }];
    }
}

- (void)setup:(WLCandy*)candy {
	self.userInteractionEnabled = YES;
    if (self.commentLabel) {
        WLComment* comment = [candy latestComment];
        self.commentLabel.text = comment.text;
        self.commentLabel.superview.hidden = !self.commentLabel.text.nonempty;
    }
	self.coverView.animatingPicture = candy.picture;
    self.coverView.url = candy.picture.small;

    [[WLMenu sharedMenu] hide];
}

- (void)select:(WLCandy*)candy {
    UIImage *largeImage = [[WLImageCache cache] imageWithUrl:candy.picture.large];
    if (candy.valid && self.coverView.state == WLImageViewStateDefault && self.coverView.image != nil && largeImage != nil) {
        if ([self.delegate respondsToSelector:@selector(candyCell:didSelectCandy:)]) {
            [self.delegate candyCell:self didSelectCandy:candy];
        }
    } else {
        [WLChronologicalEntryPresenter presentEntry:candy animated:YES];
    }
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLEntry *)entry {
	[self resetup];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return self.entry == entry;
}

@end
