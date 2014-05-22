//
//  WLWrapCandyCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandyCell.h"
#import "WLCandy.h"
#import "UIImageView+ImageLoading.h"
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
#import "WLWrapChannelBroadcaster.h"

@interface WLCandyCell () <WLWrapBroadcastReceiver, WLWrapChannelBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UIImageView *chatLabelView;
@property (weak, nonatomic) IBOutlet UIView *lowOpacityView;
@property (weak, nonatomic) IBOutlet WLBorderView *borderView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;
@property (weak, nonatomic) IBOutlet UIImageView *notifyBulb;

@property (strong, nonatomic) WLWrapChannelBroadcaster* wrapChannelBroadcaster;

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

- (WLWrapChannelBroadcaster *)wrapChannelBroadcaster {
	if (!_wrapChannelBroadcaster) {
		_wrapChannelBroadcaster = [[WLWrapChannelBroadcaster alloc] initWithReceiver:self];
	}
	return _wrapChannelBroadcaster;
}

- (void)setWrap:(WLWrap *)wrap {
	_wrap = wrap;
	self.wrapChannelBroadcaster.wrap = wrap;
}

- (void)setupItemData:(WLCandy*)entry {
	self.wrapChannelBroadcaster.candy = entry;
	self.userInteractionEnabled = YES;
	self.chatLabelView.hidden = entry.type == WLCandyTypeImage;
	if (entry.type == WLCandyTypeImage) {
		WLComment* comment = [entry.comments lastObject];
		self.commentLabel.text = comment.text;
		self.coverView.imageUrl = entry.picture.medium;
	} else {
		self.commentLabel.text = entry.chatMessage;
		self.coverView.imageUrl = entry.contributor.picture.medium;
	}
	self.commentLabel.hidden = !self.commentLabel.text.nonempty;
	
	[self refreshUploadingButtons:entry animated:NO];
	
	self.notifyBulb.hidden = ![entry updated];
}

- (void)refreshUploadingButtons:(WLCandy*)candy animated:(BOOL)animated {
	if (candy.uploadingItem) {
		self.vibrateOnLongPressGesture = NO;
		self.lowOpacityView.hidden = NO;
		self.cancelButton.hidden = (candy.uploadingItem.operation != nil);
		self.retryButton.hidden = (candy.uploadingItem.operation != nil);
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
			[WLToast showWithMessage:@"Cannot delete photo not posted by you."];
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

- (BOOL)canPerformAction:(SEL)selector withSender:(id) sender {
    return (selector == @selector(remove));
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (IBAction)select:(id)sender {
	WLCandy* candy = self.item;
	if (candy.uploadingItem == nil) {
		self.notifyBulb.hidden = YES;
		[candy setUpdated:NO];
		[self.delegate candyCell:self didSelectCandy:candy];
	}
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyChanged:(WLCandy *)candy {
	if ([candy isEqualToEntry:self.item]) {
		[self setupItemData:self.item];
	}
}

#pragma mark - WLWrapChannelBroadcastReceiver

- (void)broadcaster:(WLWrapChannelBroadcaster *)broadcaster didAddChatMessage:(WLCandy *)message {
	self.notifyBulb.hidden = ![self.item updated];
}

- (void)broadcaster:(WLWrapChannelBroadcaster *)broadcaster didAddComment:(WLCandy *)candy {
	self.item = [self.item updateWithObject:candy];
}

#pragma mark - Actions

- (IBAction)cancelUploading:(id)sender {
	WLCandy* candy = self.item;
	[self.wrap removeCandy:candy];
	[[WLUploadingQueue instance] removeItem:candy.uploadingItem];
	[self refreshUploadingButtons:self.item animated:YES];
}

- (IBAction)retryUploading:(id)sender {
	WLCandy* candy = self.item;
	[candy.uploadingItem upload:^(id object) {
	} failure:^(NSError *error) {
	}];
}

@end
