//
//  WLWrapCandyCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandyCell.h"
#import "WLCandy.h"
#import "WLImageFetcher.h"
#import "WLComment.h"
#import "WLUser.h"
#import "WLProgressBar.h"
#import "WLBorderView.h"
#import "WLWrapBroadcaster.h"
#import "WLUploadingQueue.h"
#import "WLWrap.h"
#import "UIAlertView+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "NSString+Additions.h"
#import "UIView+GestureRecognizing.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLToast.h"
#import "WLEntryState.h"
#import "WLImageFetcher.h"
#import "MFMailComposeViewController+Additions.h"

@interface WLCandyCell () <WLWrapBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UIImageView *chatLabelView;
@property (weak, nonatomic) IBOutlet UIView *lowOpacityView;
@property (weak, nonatomic) IBOutlet WLBorderView *borderView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;
@property (weak, nonatomic) IBOutlet UIImageView *notifyBulb;

@end

@implementation WLCandyCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.borderView.lineWidth = 0.5f;
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
	__weak typeof(self)weakSelf = self;
	[self addLongPressGestureRecognizing:^(CGPoint point){
		[weakSelf showMenu:point];
	}];
}

- (void)setWrap:(WLWrap *)wrap {
	_wrap = wrap;
}

- (void)setupItemData:(WLCandy*)entry {
	[self setupItemData:entry animated:NO];
}

- (void)setupItemData:(WLCandy*)candy animated:(BOOL)animated {
	self.userInteractionEnabled = YES;
	
	if ([candy isImage]) {
		WLComment* comment = [candy.comments lastObject];
		self.commentLabel.text = comment.text;
		self.coverView.url = candy.picture.medium;
	} else {
		self.commentLabel.text = candy.chatMessage;
		self.coverView.url = candy.contributor.picture.medium;
	}
	self.commentLabel.hidden = !self.commentLabel.text.nonempty;
	
	[self refreshUploadingButtons:candy animated:animated];
	
	[self refreshNotifyBulb:candy];
}

- (void)refreshNotifyBulb:(WLCandy*)candy {
	self.chatLabelView.hidden = [candy isImage];
	self.chatLabelView.alpha = 1.0f;
	if ([candy updated]) {
		self.notifyBulb.hidden = [candy isChatMessage];
		if ([candy isChatMessage]) {
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

- (void)refreshUploadingButtons:(WLCandy*)candy animated:(BOOL)animated {
	if (candy.uploading) {
		self.vibrateOnLongPressGesture = NO;
		self.lowOpacityView.hidden = NO;
		self.cancelButton.hidden = (candy.uploading.operation != nil);
		self.retryButton.hidden = (candy.uploading.operation != nil);
	} else {
		if (animated) {
			[self.lowOpacityView fade];
		}
		self.lowOpacityView.hidden = YES;
		self.vibrateOnLongPressGesture = [candy isImage] && [candy.contributor isCurrentUser];
	}
}

- (void)showMenu:(CGPoint)point {
	WLCandy* candy = self.item;
	if ([candy isImage]) {
		if ([candy.contributor isCurrentUser]) {
			UIMenuItem* menuItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(remove)];
			UIMenuController* menuController = [UIMenuController sharedMenuController];
			[self becomeFirstResponder];
			menuController.menuItems = @[menuItem];
			[menuController setTargetRect:CGRectMake(point.x, point.y, 0, 0) inView:self];
			[menuController setMenuVisible:YES animated:YES];
		} else {
			UIMenuItem* menuItem = [[UIMenuItem alloc] initWithTitle:@"Report" action:@selector(report)];
			UIMenuController* menuController = [UIMenuController sharedMenuController];
			[self becomeFirstResponder];
			menuController.menuItems = @[menuItem];
			[menuController setTargetRect:CGRectMake(point.x, point.y, 0, 0) inView:self];
			[menuController setMenuVisible:YES animated:YES];
		}
	} else {
		[WLToast showWithMessage:@"Cannot delete chat message already posted."];
	}
}

- (void)remove {
	WLCandy* candy = self.item;
	__weak typeof(self)weakSelf = self;
	weakSelf.userInteractionEnabled = NO;
	[candy remove:self.wrap success:^(id object) {
		weakSelf.userInteractionEnabled = YES;
	} failure:^(NSError *error) {
		[error show];
		weakSelf.userInteractionEnabled = YES;
	}];
}

- (void)report {
	[MFMailComposeViewController messageWithCandy:self.item andWrap:self.wrap];
}

- (BOOL)canPerformAction:(SEL)selector withSender:(id) sender {
    return (selector == @selector(remove) || selector == @selector(report));
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (IBAction)select:(id)sender {
	WLCandy* candy = self.item;
	if (candy.uploading == nil) {
		self.notifyBulb.hidden = YES;
		[candy setUpdated:NO];
		[self.delegate candyCell:self didSelectCandy:candy];
	}
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyChanged:(WLCandy *)candy {
	[self setupItemData:self.item animated:YES];
}

- (WLCandy *)broadcasterPreferedCandy:(WLWrapBroadcaster *)broadcaster {
    return self.item;
}

#pragma mark - Actions

- (IBAction)cancelUploading:(id)sender {
	WLCandy* candy = self.item;
	[self.wrap removeCandy:candy];
	[[WLUploadingQueue instance] removeUploading:candy.uploading];
	[self refreshUploadingButtons:self.item animated:YES];
}

- (IBAction)retryUploading:(id)sender {
	WLCandy* candy = self.item;
	[candy.uploading upload:^(id object) {
	} failure:^(NSError *error) {
	}];
}

@end
