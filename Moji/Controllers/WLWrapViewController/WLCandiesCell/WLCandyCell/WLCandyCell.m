//
//  WLWrapCandyCell.m
//  moji
//
//  Created by Ravenpod on 26.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandyCell.h"
#import "WLToast.h"
#import "MFMailComposeViewController+Additions.h"
#import "WLMenu.h"
#import "UIFont+CustomFonts.h"
#import "WLChronologicalEntryPresenter.h"
#import "WLDownloadingView.h"
#import "WLUploadPhotoViewController.h"
#import "WLAlertView.h"
#import "AdobeUXImageEditorViewController+SharedEditing.h"
#import "WLNavigationHelper.h"
#import "WLDrawingViewController.h"

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
                    [WLDownloadingView downloadCandy:candy success:^(UIImage *image) {
                        [AdobeUXImageEditorViewController editImage:image completion:^(UIImage *image) {
                            [candy editWithImage:image];
                        } cancel:nil];
                    } failure:^(NSError *error) {
                        [error show];
                    }];
                }];
                
                [menu addDrawPhotoItem:^(WLCandy *candy) {
                    [WLDownloadingView downloadCandy:candy success:^(UIImage *image) {
                        [WLDrawingViewController draw:image inViewController:[UIWindow mainWindow].rootViewController finish:^(UIImage *image) {
                            [candy editWithImage:image];
                        }];
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
                    [WLAlertView confirmCandyDeleting:candy success:^{
                        weakSelf.userInteractionEnabled = NO;
                        [candy remove:^(id object) {
                            weakSelf.userInteractionEnabled = YES;
                        } failure:^(NSError *error) {
                            [error show];
                            weakSelf.userInteractionEnabled = YES;
                        }];
                    } failure:nil];
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
    if (!candy) {
        self.coverView.url = nil;
        if (self.commentLabel) {
            self.commentLabel.superview.hidden = YES;
        }
        return;
    }
    if (self.commentLabel) {
        WLComment* comment = [candy latestComment];
        self.commentLabel.text = comment.text;
        self.commentLabel.superview.hidden = !self.commentLabel.text.nonempty;
    }
	self.coverView.animatingPicture = candy.picture;
    self.coverView.url = candy.picture.small;

    if (!self.disableMenu) {
        [[WLMenu sharedMenu] hide];
    }
}

- (void)select:(WLCandy*)candy {
    if (candy.valid && self.coverView.state == WLImageViewStateDefault && self.coverView.image != nil) {
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
