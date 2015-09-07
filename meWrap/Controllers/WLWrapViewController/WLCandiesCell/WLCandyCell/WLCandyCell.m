//
//  WLWrapCandyCell.m
//  meWrap
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
#import "WLAlertView.h"
#import "AdobeUXImageEditorViewController+SharedEditing.h"
#import "WLNavigationHelper.h"
#import "WLDrawingViewController.h"
#import "WLCollectionView.h"

@interface WLCandyCell () <WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet WLImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;

@end

@implementation WLCandyCell

- (void)awakeFromNib {
	[super awakeFromNib];
    
	[[WLCandy notifier] addReceiver:self];
    __weak typeof(self)weakSelf = self;
    if (!self.disableMenu) {
        [[WLMenu sharedMenu] addView:self configuration:^(WLMenu *menu) {
            __weak WLCandy* candy = weakSelf.entry;
            
            if (candy.wrap.requiresFollowing) {
                return;
            }
            
            [candy prepareForUpdate:^(WLContribution *contribution, WLContributionStatus status) {
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
                        [WLDrawingViewController draw:image finish:^(UIImage *image) {
                            [candy editWithImage:image];
                        }];
                    } failure:^(NSError *error) {
                        [error show];
                    }];
                }];
            } failure:nil];
            
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
            menu.entry = candy;
        }];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.coverView setImage:nil];
}

- (void)setup:(WLCandy*)candy {
	self.userInteractionEnabled = YES;
    if (self.commentLabel) {
        WLComment* comment = [candy latestComment];
        self.commentLabel.text = comment.text;
        self.commentLabel.superview.hidden = !self.commentLabel.text.nonempty;
    }
    
    WLPicture *picture = candy.picture;
    
    if (picture.justUploaded) {
        [self.coverView setImageSetter:^(WLImageView *imageView, UIImage *image, BOOL animated) {
            picture.justUploaded = NO;
            [WLCollectionView lock];
            run_after_asap(^{
                imageView.image = image;
                NSTimeInterval duration = 0.5f;
                [imageView fadeWithDuration:duration delegate:nil];
                run_after(duration, ^{
                    [WLCollectionView unlock];
                });
            });
        }];
    } else {
        self.coverView.imageSetter = nil;
    }
    
    self.coverView.url = picture.small;

    [[WLMenu sharedMenu] hide];
}

- (void)select:(WLCandy*)candy {
    if (candy.valid && self.coverView.image != nil) {
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
