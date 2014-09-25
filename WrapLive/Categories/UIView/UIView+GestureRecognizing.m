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

@property (strong, nonatomic) WLGestureBlock gestureBlock;

@property (strong, nonatomic) UITapGestureRecognizer* wl_tapGestureRecognizer;

@property (strong, nonatomic) UISwipeGestureRecognizer *wl_swipeGestureRecognizer;

@end

@implementation UIView (GestureRecognizing)

- (void)setGestureBlock:(WLGestureBlock)gestureBlock {
	[self setAssociatedObject:gestureBlock forKey:"wl_gestureBlock"];
}

- (WLGestureBlock)gestureBlock {
	return [self associatedObjectForKey:"wl_gestureBlock"];
}

- (void)setWl_tapGestureRecognizer:(UITapGestureRecognizer *)wl_tapGestureRecognizer {
	[self setAssociatedObject:wl_tapGestureRecognizer forKey:"wl_tapGestureRecognizer"];
}

- (UITapGestureRecognizer *)wl_tapGestureRecognizer {
	return [self associatedObjectForKey:"wl_tapGestureRecognizer"];
}

- (void)setWl_swipeGestureRecognizer:(UISwipeGestureRecognizer *)wl_swipeGestureRecognizer {
    [self setAssociatedObject:wl_swipeGestureRecognizer forKey:"wl_swipeGestureRecognizer"];
}

- (UISwipeGestureRecognizer *)wl_swipeGestureRecognizer {
    return [self associatedObjectForKey:"wl_swipeGestureRecognizer"];
}

- (void)addTapGestureRecognizingDelegate:(id)delegate block:(WLGestureBlock)block  {
	if (self.wl_tapGestureRecognizer == nil) {
		UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(action:)];
		[self addGestureRecognizer:tapGestureRecognizer];
        [tapGestureRecognizer setAssociatedObject:block forKey:"gestureBlock"];
		self.wl_tapGestureRecognizer = tapGestureRecognizer;
        self.wl_tapGestureRecognizer.delegate = delegate;
	}
}

- (void)addTapGestureRecognizing:(WLGestureBlock)block {
    [self addTapGestureRecognizingDelegate:nil block:block];
}

- (void)removeTapGestureRecognizing {
	UITapGestureRecognizer* tapGestureRecognizer = self.wl_tapGestureRecognizer;
	if (tapGestureRecognizer) {
		[self removeGestureRecognizer:tapGestureRecognizer];
		self.wl_tapGestureRecognizer = nil;
	}
}

- (void)addSwipeGestureRecognizingDelegate:(id)delegate
                            direction:(UISwipeGestureRecognizerDirection)direction
                                block:(WLGestureBlock)block {
    if (self.wl_swipeGestureRecognizer == nil) {
        UISwipeGestureRecognizer *swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]
                                                            initWithTarget:self action:@selector(action:)];
        [swipeGestureRecognizer setAssociatedObject:block forKey:"gestureBlock"];
        swipeGestureRecognizer.direction = direction;
        [self addGestureRecognizer:swipeGestureRecognizer];
        self.wl_swipeGestureRecognizer = swipeGestureRecognizer;
        self.wl_swipeGestureRecognizer.delegate = delegate;
    }
}

- (void)addSwipeGestureRecognizingDelegate:(id)delegate block:(WLGestureBlock)block {
    [self addSwipeGestureRecognizingDelegate:delegate
                                   direction:kNilOptions
                                       block:block];
}

- (void)addSwipeGestureRecognizing:(WLGestureBlock)block {
    [self addSwipeGestureRecognizingDelegate:nil block:block];
}

#pragma mark - Actions

- (void)action:(UIGestureRecognizer*)sender {
	WLGestureBlock gestureBlock = [sender associatedObjectForKey:"gestureBlock"];
	if (gestureBlock) {
		gestureBlock(sender);
	}
}

@end
