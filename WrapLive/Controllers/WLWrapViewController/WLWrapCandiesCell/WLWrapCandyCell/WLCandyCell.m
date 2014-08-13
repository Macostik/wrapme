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
@property (weak, nonatomic) IBOutlet UIImageView *chatLabelView;
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
        if ([candy isImage]) {
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
        } else {
            [WLToast showWithMessage:@"Cannot delete chat message already posted."];
            return NO;
        }
    }];
}

- (void)setup:(WLCandy*)candy {
	self.userInteractionEnabled = YES;
	if ([candy isImage]) {
		WLComment* comment = [candy.comments lastObject];
		self.commentLabel.text = comment.text;
		self.coverView.url = candy.picture.medium;
        self.menu.vibrate = YES;
	} else {
		self.commentLabel.text = candy.message;
		self.coverView.url = candy.contributor.picture.medium;
        self.menu.vibrate = NO;
	}
	self.commentLabel.hidden = !self.commentLabel.text.nonempty;
    
	[self refreshNotifyBulb:candy];
}

- (void)refreshNotifyBulb:(WLCandy*)candy {
	self.chatLabelView.hidden = [candy isImage];
	self.chatLabelView.alpha = 1.0f;
	if ([[candy unread] boolValue]) {
		self.notifyBulb.hidden = [candy isMessage];
		if ([candy isMessage]) {
			__weak typeof(self)weakSelf = self;
			[self.chatLabelView.layer removeAllAnimations];
			[UIView animateWithDuration:1.5f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionBeginFromCurrentState animations:^{
				weakSelf.chatLabelView.alpha = 0.0f;
			} completion:^(BOOL finished) {
			}];
		}
	} else {
		self.notifyBulb.hidden = YES;
	}
}

- (IBAction)select:(id)sender {
	WLCandy* candy = self.entry;
    if (candy.valid) {
        self.notifyBulb.hidden = YES;
        candy.unread = @NO;
        [super select:sender];
    }
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyChanged:(WLCandy *)candy {
	[self setup:self.entry];
}

- (WLCandy *)broadcasterPreferedCandy:(WLWrapBroadcaster *)broadcaster {
    return self.entry;
}

@end
