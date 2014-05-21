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

@property (strong, nonatomic) WLPointBlock longPressGestureBlock;

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

- (void)setLongPressGestureBlock:(WLPointBlock)longPressGestureBlock {
	[self setAssociatedObject:longPressGestureBlock forKey:"wl_longPressGestureBlock"];
}

- (WLPointBlock)longPressGestureBlock {
	return [self associatedObjectForKey:"wl_longPressGestureBlock"];
}

- (void)setVibrateOnLongPressGesture:(BOOL)vibrateOnLongPressGesture {
	[self setAssociatedObject:@(vibrateOnLongPressGesture) forKey:"wl_vibrateOnLongPressGesture"];
}

- (BOOL)vibrateOnLongPressGesture {
	return [[self associatedObjectForKey:"wl_vibrateOnLongPressGesture"] boolValue];
}

- (void)addTapGestureRecognizing:(WLPointBlock)block {
	self.tapGestureBlock = block;
	UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
	[self addGestureRecognizer:tapGestureRecognizer];
	self.wl_tapGestureRecognizer = tapGestureRecognizer;
}

- (void)removeTapGestureRecognizing {
	UITapGestureRecognizer* tapGestureRecognizer = self.wl_tapGestureRecognizer;
	if (tapGestureRecognizer) {
		[self removeGestureRecognizer:tapGestureRecognizer];
	}
}

- (void)addLongPressGestureRecognizing:(WLPointBlock)block {
	self.vibrateOnLongPressGesture = YES;
	self.longPressGestureBlock = block;
	UILongPressGestureRecognizer* longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
	[self addGestureRecognizer:longPressGestureRecognizer];
}

#pragma mark - Actions

- (void)longPress:(UILongPressGestureRecognizer*)sender {
	if (sender.state == UIGestureRecognizerStateBegan && self.userInteractionEnabled) {
		if (self.vibrateOnLongPressGesture) {
			AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
		}
		WLPointBlock longPressGestureBlock = self.longPressGestureBlock;
		if (longPressGestureBlock) {
			longPressGestureBlock([sender locationInView:self]);
		}
	}
}

- (void)tap:(UITapGestureRecognizer*)sender {
	WLPointBlock longPressGestureBlock = self.tapGestureBlock;
	if (longPressGestureBlock) {
		longPressGestureBlock([sender locationInView:self]);
	}
}

@end
