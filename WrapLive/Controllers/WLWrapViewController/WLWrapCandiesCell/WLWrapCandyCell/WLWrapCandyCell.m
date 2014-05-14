//
//  WLWrapCandyCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapCandyCell.h"
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

@interface WLWrapCandyCell () <WLWrapBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UIImageView *chatLabelView;
@property (weak, nonatomic) IBOutlet UIView *lowOpacityView;
@property (weak, nonatomic) IBOutlet WLBorderView *borderView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;

@end

@implementation WLWrapCandyCell

- (void)awakeFromNib {
	[super awakeFromNib];
	self.borderView.lineWidth = 0.5f;
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
	__weak typeof(self)weakSelf = self;
	[self addLongPressGestureRecognizing:^(CGPoint point){
		[weakSelf showMenu:point];
	}];
}

- (void)setupItemData:(WLCandy*)entry {
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
	
	[self refreshUploadingButtons:entry];
	
	self.vibrateOnLongPressGesture = [entry.contributor isCurrentUser];
}

- (void)refreshUploadingButtons:(WLCandy*)candy {
	if (candy.uploadingItem) {
		self.lowOpacityView.hidden = NO;
		self.cancelButton.hidden = (candy.uploadingItem.operation != nil);
		self.retryButton.hidden = (candy.uploadingItem.operation != nil);
	} else {
		__weak typeof(self)weakSelf = self;
		[UIView animateWithDuration:0.3f animations:^{
			weakSelf.lowOpacityView.alpha = 0.0f;
		} completion:^(BOOL finished) {
			weakSelf.lowOpacityView.hidden = YES;
			weakSelf.lowOpacityView.alpha = 1.0f;
		}];
	}
}

- (void)showMenu:(CGPoint)point {
	WLCandy* candy = self.item;
	if ([candy isImage] && [candy.contributor isCurrentUser]) {
		UIMenuItem* menuItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(remove)];
		UIMenuController* menuController = [UIMenuController sharedMenuController];
		[self becomeFirstResponder];
		menuController.menuItems = @[menuItem];
		[menuController setTargetRect:CGRectMake(point.x, point.y, 0, 0) inView:self];
		[menuController setMenuVisible:YES animated:YES];
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

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyChanged:(WLCandy *)candy {
	if ([candy isEqualToEntry:self.item]) {
		[self refreshUploadingButtons:self.item];
	}
}

#pragma mark - Actions

- (IBAction)cancelUploading:(id)sender {
	WLCandy* candy = self.item;
	[self.wrap removeCandy:candy];
	[[WLUploadingQueue instance] removeItem:candy.uploadingItem];
	[self refreshUploadingButtons:self.item];
}

- (IBAction)retryUploading:(id)sender {
	WLCandy* candy = self.item;
	[candy.uploadingItem upload:^(id object) {
	} failure:^(NSError *error) {
	}];
}

@end
