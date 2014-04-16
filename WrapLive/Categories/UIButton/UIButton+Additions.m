//
//  UIButton+Additions.m
//  WrapLive
//
//  Created by Sergey Maximenko on 15.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIButton+Additions.h"

@implementation UIButton (Additions)

- (void)setActive:(BOOL)active {
	[self setActive:active animated:NO];
}

- (BOOL)active {
	return self.alpha > 0.5 && self.userInteractionEnabled;
}

- (void)setActive:(BOOL)active animated:(BOOL)animated {
	if (animated) {
		[UIView beginAnimations:nil context:nil];
	}
	self.alpha = active ? 1.0f : 0.5f;
	self.userInteractionEnabled = active;
	if (animated) {
		[UIView commitAnimations];
	}
}

@end
