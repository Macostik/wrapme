//
//  WLWrapCandyCell.m
//  meWrap
//
//  Created by Ravenpod on 26.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandyCell.h"
#import "WLToast.h"
#import "WLMenu.h"
#import "WLChronologicalEntryPresenter.h"
#import "WLDownloadingView.h"
#import "WLAlertView.h"
#import "WLNavigationHelper.h"
#import "WLDrawingViewController.h"
#import "PHPhotoLibrary+Helper.h"
#import "WLEntry+WLUploadingQueue.h"
#import "WLImageEditorSession.h"

@interface WLCandyCell () <WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet WLImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UIView *videoIndicatorView;

@end

@implementation WLCandyCell

- (void)awakeFromNib {
	[super awakeFromNib];
    self.exclusiveTouch = YES;
}

- (void)setMetrics:(StreamMetrics *)metrics {
    [super setMetrics:metrics];
    if (!metrics.disableMenu) {
        __weak typeof(self)weakSelf = self;
        [[WLMenu sharedMenu] addView:self configuration:^(WLMenu *menu) {
            __weak WLCandy* candy = weakSelf.entry;
            
            if (candy.wrap.requiresFollowing) {
                return;
            }
            
            [candy prepareForUpdate:^(WLContribution *contribution, WLContributionStatus status) {
                [menu addEditPhotoItem:^(WLCandy *candy) {
                    [WLDownloadingView downloadCandy:candy success:^(UIImage *image) {
                        [WLImageEditorSession editImage:image completion:^(UIImage *image) {
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
                    [WLToast showDownloadingMediaMessageForCandy:candy];
                } failure:^(NSError *error) {
                    [error show];
                }];
            }];
            
            if (candy.deletable) {
                [menu addDeleteItem:^(WLCandy *candy) {
                    [UIAlertController confirmCandyDeleting:candy success:^{
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
                    ReportViewController *controller = [[UIStoryboard storyboardNamed:WLMainStoryboard] instantiateViewControllerWithIdentifier:@"report"];;
                    [controller setReportClosure:^(NSString * code, ReportViewController *controller) {
                        [[WLAPIRequest postCandy:candy violationCode:code] send:^(id object) {
                            [controller reportingFinished];
                        } failure:^(NSError *error) {
                            [error show];
                        }];
                    }];
                    [[UIWindow mainWindow].rootViewController presentViewController:controller animated:NO completion:nil];
                }];
            }
            menu.entry = candy;
        }];
    }
}

- (void)didDequeue {
    [super didDequeue];
    [self.coverView setImage:nil];
}

- (void)setup:(WLCandy*)candy {
	self.userInteractionEnabled = YES;
    if (!candy) {
        self.videoIndicatorView.hidden = YES;
        self.coverView.url = nil;
        if (self.commentLabel) {
            self.commentLabel.superview.hidden = YES;
        }
        return;
    }
    
    self.videoIndicatorView.hidden = candy.type != WLCandyTypeVideo;
    if (self.commentLabel) {
        WLComment* comment = [candy latestComment];
        self.commentLabel.text = comment.text;
        self.commentLabel.superview.hidden = !self.commentLabel.text.nonempty;
    }
    
    WLAsset *picture = candy.picture;
    
    if (picture.justUploaded) {
        [StreamView lock];
        self.alpha = 0.0;
        __weak typeof(self)weakSelf = self;
        [UIView animateWithDuration:0.5 animations:^{
            weakSelf.alpha = 1;
        } completion:^(BOOL finished) {
            picture.justUploaded = NO;
            [StreamView unlock];
        }];
    }
    
    self.coverView.url = picture.small;
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLEntry *)entry {
	[self resetup];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return self.entry == entry;
}

@end
