//
//  UIView+GestureRecognizing.m
//  meWrap
//
//  Created by Ravenpod on 12.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "UIView+GestureRecognizing.h"
#import "NSObject+AssociatedObjects.h"

@implementation UIView (GestureRecognizing)

- (void)removeGestureRecognizerWithIdentifier:(NSString*)identifier {
    for (UIGestureRecognizer *recognizer in [self.gestureRecognizers copy]) {
        if ([recognizer.identifier isEqualToString:identifier]) {
            [self removeGestureRecognizer:recognizer];
        }
    }
}

@end

@implementation UIGestureRecognizer (Helper)

+ (instancetype)recognizerWithView:(UIView*)view block:(WLGestureBlock)block {
    return [self recognizerWithView:view identifier:nil block:block];
}

+ (instancetype)recognizerWithView:(UIView*)view identifier:(NSString *)identifier block:(WLGestureBlock)block {
    return [[self alloc] initWithView:view identifier:identifier block:block];
}

- (instancetype)initWithView:(UIView*)view block:(WLGestureBlock)block {
    return [self initWithView:view identifier:nil block:block];
}

- (instancetype)initWithView:(UIView*)view identifier:(NSString *)identifier block:(WLGestureBlock)block {
    self = [self init];
    if (self) {
        [self addTarget:self action:@selector(action:)];
        self.gestureBlock = block;
        self.identifier = identifier;
        [view addGestureRecognizer:self];
    }
    return self;
}

- (void)action:(UIGestureRecognizer*)sender {
    WLGestureBlock gestureBlock = sender.gestureBlock;
    if (gestureBlock) {
        gestureBlock(sender);
    }
}

- (void)setGestureBlock:(WLGestureBlock)gestureBlock {
    [self setAssociatedObject:gestureBlock forKey:"wl_gestureBlock"];
}

- (WLGestureBlock)gestureBlock {
    return [self associatedObjectForKey:"wl_gestureBlock"];
}

- (void)setIdentifier:(NSString *)identifier {
    [self setAssociatedObject:identifier forKey:"wl_identifier"];
}

- (NSString *)identifier {
    return [self associatedObjectForKey:"wl_identifier"];
}

@end
