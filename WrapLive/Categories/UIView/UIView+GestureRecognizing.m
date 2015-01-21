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

@property (strong, nonatomic) UITapGestureRecognizer* wl_tapGestureRecognizer;

@property (strong, nonatomic) UISwipeGestureRecognizer *wl_swipeGestureRecognizer;

@property (strong, nonatomic) UILongPressGestureRecognizer *wl_longGestureRecognizer;

@end

@implementation UIView (GestureRecognizing)

- (void)setWl_tapGestureRecognizer:(UITapGestureRecognizer *)wl_tapGestureRecognizer {
	[self setAssociatedObject:wl_tapGestureRecognizer forKey:"wl_tapGestureRecognizer"];
}

- (UITapGestureRecognizer *)wl_tapGestureRecognizer {
	return [self associatedObjectForKey:"wl_tapGestureRecognizer"];
}

- (void)setWl_longGestureRecognizer:(UILongPressGestureRecognizer *)wl_longGestureRecognizer {
    [self setAssociatedObject:wl_longGestureRecognizer forKey:"wl_longGestureRecognizer"];
}

- (UILongPressGestureRecognizer *)wl_longGestureRecognizer {
    return [self associatedObjectForKey:"wl_longGestureRecognizer"];
}

- (void)setWl_swipeGestureRecognizer:(UISwipeGestureRecognizer *)wl_swipeGestureRecognizer {
    [self setAssociatedObject:wl_swipeGestureRecognizer forKey:"wl_swipeGestureRecognizer"];
}

- (UISwipeGestureRecognizer *)wl_swipeGestureRecognizer {
    return [self associatedObjectForKey:"wl_swipeGestureRecognizer"];
}

- (void)addTapGestureRecognizing:(WLGestureBlock)block {
    [self addTapGestureRecognizingDelegate:nil block:block];
}

- (void)addTapGestureRecognizingDelegate:(id)delegate block:(WLGestureBlock)block {
	if (self.wl_tapGestureRecognizer == nil) {
        UITapGestureRecognizer *tapGestureRecognizer = [UITapGestureRecognizer recognizerWithBlock:block];
		self.wl_tapGestureRecognizer = tapGestureRecognizer;
        self.wl_tapGestureRecognizer.delegate = delegate;
        [self addGestureRecognizer:tapGestureRecognizer];
	}
}

- (void)addLongPressGestureRecognizing:(WLGestureBlock)block {
    UILongPressGestureRecognizer *longGestureRecognizer = [UILongPressGestureRecognizer recognizerWithBlock:block];
    [self addLongPressGestureRecognizingDelegate:nil minimunPressDuratioin:longGestureRecognizer.minimumPressDuration block:block];
}

- (void)addLongPressGestureRecognizingDelegate:(id)delegate minimunPressDuratioin:(CGFloat)duration block:(WLGestureBlock)block {
    if (self.wl_longGestureRecognizer == nil) {
        UILongPressGestureRecognizer *longGestureRecognizer = [UILongPressGestureRecognizer recognizerWithBlock:block];
        self.wl_longGestureRecognizer.minimumPressDuration = duration;
        self.wl_longGestureRecognizer = longGestureRecognizer;
        self.wl_longGestureRecognizer.delegate = delegate;
        [self addGestureRecognizer:longGestureRecognizer];
    }
}

- (void)addSwipeGestureRecognizing:(WLGestureBlock)block {
    [self addSwipeGestureRecognizingDelegate:nil block:block];
}

- (void)addSwipeGestureRecognizingDelegate:(id)delegate block:(WLGestureBlock)block {
    [self addSwipeGestureRecognizingDelegate:delegate
                                   direction:kNilOptions
                                       block:block];
}

- (void)addSwipeGestureRecognizingDelegate:(id)delegate
                            direction:(UISwipeGestureRecognizerDirection)direction
                                block:(WLGestureBlock)block {
    if (self.wl_swipeGestureRecognizer == nil) {
        UISwipeGestureRecognizer *swipeGestureRecognizer = [UISwipeGestureRecognizer recognizerWithBlock:block];
        swipeGestureRecognizer.direction = direction;
        self.wl_swipeGestureRecognizer = swipeGestureRecognizer;
        self.wl_swipeGestureRecognizer.delegate = delegate;
        [self addGestureRecognizer:swipeGestureRecognizer];
    }
}

- (void)removeGestureRecognizing:(UIGestureRecognizer *)recognizer {
    if (recognizer) {
        [self removeGestureRecognizer:recognizer];
        recognizer = nil;
    }
}

- (void)removeTapGestureRecognizing {
    [self removeGestureRecognizer:self.wl_tapGestureRecognizer];
}

- (void)removeLongPressGestureRecognizing {
    [self removeGestureRecognizer:self.wl_longGestureRecognizer];
}

- (void)removeSwipeGestureRecognizing {
    [self removeGestureRecognizer:self.wl_swipeGestureRecognizer];
}

@end

@implementation UIGestureRecognizer (Helper)

+ (id)recognizerWithBlock:(WLGestureBlock)block  {
    id gestureRecognizer = [self new];
    [gestureRecognizer addTarget:gestureRecognizer action:@selector(action:)];
    [gestureRecognizer setAssociatedObject:block forKey:"gestureBlock"];
    return gestureRecognizer;
}

- (void)action:(UIGestureRecognizer*)sender {
    WLGestureBlock gestureBlock = [sender associatedObjectForKey:"gestureBlock"];
    if (gestureBlock) {
        gestureBlock(sender);
    }
}

@end
