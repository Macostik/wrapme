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

@property (strong, nonatomic) WLBlock longPressGestureBlock;

@property (strong, nonatomic) WLBlock tapGestureBlock;

@property (strong, nonatomic) UITapGestureRecognizer* tapGestureRecognizer;

@end

@implementation UIView (GestureRecognizing)

- (void)setTapGestureBlock:(WLBlock)tapGestureBlock {
	[self setAssociatedObject:tapGestureBlock forKey:@"tapGestureBlock"];
}

- (WLBlock)tapGestureBlock {
	return [self associatedObjectForKey:@"tapGestureBlock"];
}

- (void)setTapGestureRecognizer:(UITapGestureRecognizer *)tapGestureRecognizer {
	[self setAssociatedObject:tapGestureRecognizer forKey:@"tapGestureRecognizer"];
}

- (UITapGestureRecognizer *)tapGestureRecognizer {
	return [self associatedObjectForKey:@"tapGestureRecognizer"];
}

- (void)setLongPressGestureBlock:(WLBlock)longPressGestureBlock {
	[self setAssociatedObject:longPressGestureBlock forKey:@"longPressGestureBlock"];
}

- (WLBlock)longPressGestureBlock {
	return [self associatedObjectForKey:@"longPressGestureBlock"];
}

- (void)addTapGestureRecognizing:(WLBlock)block {
	self.tapGestureBlock = block;
	UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
	[self addGestureRecognizer:tapGestureRecognizer];
	self.tapGestureRecognizer = tapGestureRecognizer;
}

- (void)removeTapGestureRecognizing {
	UITapGestureRecognizer* tapGestureRecognizer = self.tapGestureRecognizer;
	if (tapGestureRecognizer) {
		[self removeGestureRecognizer:tapGestureRecognizer];
	}
}

- (void)addLongPressGestureRecognizing:(WLBlock)block {
	self.longPressGestureBlock = block;
	UILongPressGestureRecognizer* longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
	[self addGestureRecognizer:longPressGestureRecognizer];
}

#pragma mark - Actions

- (void)longPress:(UILongPressGestureRecognizer*)sender {
	if (sender.state == UIGestureRecognizerStateBegan && self.userInteractionEnabled) {
		AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
		WLBlock longPressGestureBlock = self.longPressGestureBlock;
		if (longPressGestureBlock) {
			longPressGestureBlock();
		}
	}
}

- (void)tap:(UITapGestureRecognizer*)sender {
	WLBlock longPressGestureBlock = self.tapGestureBlock;
	if (longPressGestureBlock) {
		longPressGestureBlock();
	}
}

@end
