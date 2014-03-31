//
//  WLComposeContriner.m
//  WrapLive
//
//  Created by Sergey Maximenko on 31.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLComposeContainer.h"
#import "WLComposeBar.h"
#import "UIView+Shorthand.h"

@interface WLComposeContainer ()

@property (nonatomic, weak) IBOutlet UIView* view;
@property (nonatomic, weak) IBOutlet WLComposeBar* composeBar;

@end

@implementation WLComposeContainer

- (void)awakeFromNib {
	[super awakeFromNib];
	self.editing = NO;
}

- (void)setEditing:(BOOL)editing {
	[self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	_editing = editing;
	
	if (!editing) {
		[self.composeBar resignFirstResponder];
	}
	
	__weak typeof(self)weakSelf = self;
	
	CGRect viewRect;
	CGFloat composeBarAlpha = editing ? 1.0f : 0.0f;
	
	if (self.contentMode == UIViewContentModeBottom) {
		viewRect = editing ? CGRectMake(0, 0, self.width, self.height - self.composeBar.height) : self.bounds;
	} else {
		viewRect = editing ? CGRectMake(0, self.composeBar.height, self.width, self.height - self.composeBar.height) : self.bounds;
	}
	
	[UIView animateWithDuration:animated ? 0.3f : 0.0f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		weakSelf.composeBar.alpha = composeBarAlpha;
		weakSelf.view.frame = viewRect;
	} completion:^(BOOL finished) {
		if (editing) {
			[weakSelf.composeBar becomeFirstResponder];
		}
	}];
}

@end
