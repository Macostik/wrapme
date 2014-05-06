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
	UILongPressGestureRecognizer* removeGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(remove:)];
	[self addGestureRecognizer:removeGestureRecognizer];
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
	self.commentLabel.hidden = !self.commentLabel.text.length > 0;
	
	[self refreshUploadingButtons:entry];
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

- (void)remove:(UILongPressGestureRecognizer*)sender {
	if (sender.state == UIGestureRecognizerStateBegan && self.userInteractionEnabled) {
		WLCandy* candy = self.item;
		if ([candy isImage] && [candy.contributor isCurrentUser]) {
			__weak typeof(self)weakSelf = self;
			[UIActionSheet showWithTitle:nil cancel:@"Cancel" destructive:@"Delete" buttons:nil completion:^(NSUInteger index) {
				[UIActionSheet showWithTitle:@"Are you sure you want to delete this candy?" cancel:@"No" destructive:@"Yes" buttons:nil completion:^(NSUInteger index) {
					weakSelf.userInteractionEnabled = NO;
					[[WLAPIManager instance] removeCandy:candy wrap:self.wrap success:^(id object) {
						weakSelf.userInteractionEnabled = YES;
					} failure:^(NSError *error) {
						[error show];
						weakSelf.userInteractionEnabled = YES;
					}];
				}];
			}];
		}
	}
}

@end
