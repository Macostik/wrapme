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

@interface WLCandyCell () <WLWrapBroadcastReceiver, WLMenuDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UIImageView *chatLabelView;
@property (weak, nonatomic) IBOutlet UIImageView *notifyBulb;

@property (strong, nonatomic) WLMenu* menu;

@end

@implementation WLCandyCell

- (void)awakeFromNib {
	[super awakeFromNib];
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
    self.menu = [WLMenu menuWithView:self delegate:self];
}

- (void)setupItemData:(WLCandy*)candy {
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
	WLCandy* candy = self.item;
	self.notifyBulb.hidden = YES;
    candy.unread = @NO;
    [self.delegate candyCell:self didSelectCandy:candy];
}

#pragma mark - WLMenuDelegate

- (void)remove {
	WLCandy* candy = self.item;
	__weak typeof(self)weakSelf = self;
	weakSelf.userInteractionEnabled = NO;
	[candy remove:^(id object) {
		weakSelf.userInteractionEnabled = YES;
	} failure:^(NSError *error) {
		[error show];
		weakSelf.userInteractionEnabled = YES;
	}];
}

- (void)report {
	[MFMailComposeViewController messageWithCandy:self.item];
}

- (BOOL)menuShouldBePresented:(WLMenu *)menu {
    WLCandy* candy = self.item;
    if ([candy isImage]) {
        return YES;
    } else {
        [WLToast showWithMessage:@"Cannot delete chat message already posted."];
        return NO;
    }
}

- (NSString *)menu:(WLMenu *)menu titleForItem:(NSUInteger)item {
    WLCandy* candy = self.item;
    return [candy.contributor isCurrentUser] ? @"Delete" : @"Report";
}

- (SEL)menu:(WLMenu *)menu actionForItem:(NSUInteger)item {
    WLCandy* candy = self.item;
    return [candy.contributor isCurrentUser] ? @selector(remove) : @selector(report);
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyChanged:(WLCandy *)candy {
	[self setupItemData:self.item];
}

- (WLCandy *)broadcasterPreferedCandy:(WLWrapBroadcaster *)broadcaster {
    return self.item;
}

@end
