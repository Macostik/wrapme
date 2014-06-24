//
//  UIView+GestureRecognizing.m
//  WrapLive
//
//  Created by Sergey Maximenko on 12.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIView+GestureRecognizing.h"
#import "NSObject+AssociatedObjects.h"
#import <AudioToolbox/AudioServices.h>

@interface UIView ()

@property (strong, nonatomic) WLPointBlock tapGestureBlock;

@property (strong, nonatomic) UITapGestureRecognizer* wl_tapGestureRecognizer;

@end

@implementation UIView (GestureRecognizing)

- (void)setTapGestureBlock:(WLPointBlock)tapGestureBlock {
	[self setAssociatedObject:tapGestureBlock forKey:"wl_tapGestureBlock"];
}

- (WLPointBlock)tapGestureBlock {
	return [self associatedObjectForKey:"wl_tapGestureBlock"];
}

- (void)setWl_tapGestureRecognizer:(UITapGestureRecognizer *)tapGestureRecognizer {
	[self setAssociatedObject:tapGestureRecognizer forKey:"wl_tapGestureRecognizer"];
}

- (UITapGestureRecognizer *)wl_tapGestureRecognizer {
	return [self associatedObjectForKey:"wl_tapGestureRecognizer"];
}

- (void)addTapGestureRecognizing:(WLPointBlock)block {
	if (self.wl_tapGestureRecognizer == nil) {
		self.tapGestureBlock = block;
		UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
		[self addGestureRecognizer:tapGestureRecognizer];
		self.wl_tapGestureRecognizer = tapGestureRecognizer;
	}
}

- (void)removeTapGestureRecognizing {
	UITapGestureRecognizer* tapGestureRecognizer = self.wl_tapGestureRecognizer;
	if (tapGestureRecognizer) {
		[self removeGestureRecognizer:tapGestureRecognizer];
		self.wl_tapGestureRecognizer = nil;
	}
}

#pragma mark - Actions

- (void)tap:(UITapGestureRecognizer*)sender {
	WLPointBlock longPressGestureBlock = self.tapGestureBlock;
	if (longPressGestureBlock) {
		longPressGestureBlock([sender locationInView:self]);
	}
}

@end
