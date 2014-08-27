//
//  WLWrapCandyCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandyCell.h"
#import "WLImageFetcher.h"
#import "WLProgressBar.h"
#import "WLBorderView.h"
#import "WLWrapBroadcaster.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "NSString+Additions.h"
#import "UIView+GestureRecognizing.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLToast.h"
#import "WLImageFetcher.h"
#import "MFMailComposeViewController+Additions.h"
#import "WLUploading.h"
#import "WLUser.h"
#import "WLAPIManager.h"
#import "WLEntryManager.h"
#import "WLMenu.h"

@interface WLCandyCell () <WLWrapBroadcastReceiver>

@property (weak, nonatomic) IBOutlet WLImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UIImageView *notifyBulb;

@property (strong, nonatomic) WLMenu* menu;

@end

@implementation WLCandyCell

- (void)awakeFromNib {
	[super awakeFromNib];
    self.coverView.placeholderName = @"ic_photo_placeholder";
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
    __weak typeof(self)weakSelf = self;
    self.menu = [WLMenu menuWithView:self configuration:^BOOL (WLMenu *menu) {
        WLCandy* candy = weakSelf.entry;
        if ([candy.contributor isCurrentUser] || [candy.wrap.contributor isCurrentUser]) {
            [menu addItem:@"Delete" block:^{
                weakSelf.userInteractionEnabled = NO;
                [candy remove:^(id object) {
                    weakSelf.userInteractionEnabled = YES;
                } failure:^(NSError *error) {
                    [error show];
                    weakSelf.userInteractionEnabled = YES;
                }];
            }];
        } else {
            [menu addItem:@"Report" block:^{
                [MFMailComposeViewController messageWithCandy:candy];
            }];
        }
        return YES;
    }];
    self.menu.vibrate = YES;
}

- (void)setup:(WLCandy*)candy {
	self.userInteractionEnabled = YES;
	WLComment* comment = [candy.comments lastObject];
    self.commentLabel.text = comment.text;
    self.commentLabel.hidden = !self.commentLabel.text.nonempty;
	self.coverView.animatingPicture = candy.picture;
    self.coverView.url = candy.picture.medium;
	self.notifyBulb.hidden = ![[candy unread] boolValue];
}

- (IBAction)select:(id)entry {
	WLCandy* candy = self.entry;
    if (candy.valid) {
        self.notifyBulb.hidden = YES;
        candy.unread = @NO;
        [super select:entry];
    }
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyChanged:(WLCandy *)candy {
	[self resetup];
}

- (WLCandy *)broadcasterPreferedCandy:(WLWrapBroadcaster *)broadcaster {
    return self.entry;
}

@end
