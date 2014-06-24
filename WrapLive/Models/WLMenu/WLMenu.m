//
//  WLMenu.m
//  WrapLive
//
//  Created by Sergey Maximenko on 6/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLMenu.h"
#import <AudioToolbox/AudioServices.h>

@interface WLMenu ()

@property (readonly, nonatomic) NSUInteger numberOfItems;

@end

@implementation WLMenu
{
    BOOL _vibrate:YES;
}

@synthesize vibrate = _vibrate;

+ (instancetype)menuWithView:(UIView *)view delegate:(UIResponder<WLMenuDelegate> *)delegate {
    return [[self alloc] initWithView:view delegate:delegate];
}

- (instancetype)initWithView:(UIView *)view delegate:(UIResponder<WLMenuDelegate> *)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        UILongPressGestureRecognizer* longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(present:)];
        [view addGestureRecognizer:longPressGestureRecognizer];
    }
    return self;
}

- (NSUInteger)numberOfItems {
    NSUInteger numberOfItems = 1;
    if ([self.delegate respondsToSelector:@selector(menuNumberOfItems:)]) {
        numberOfItems = [self.delegate menuNumberOfItems:self];
    }
    return numberOfItems;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)isMenuAction:(SEL)action {
    NSUInteger numberOfItems = self.numberOfItems;
    for (NSUInteger item = 0; item < numberOfItems; ++item) {
        if ([self.delegate menu:self actionForItem:item] == action) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return [self isMenuAction:action];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if ([super methodSignatureForSelector:sel]) {
        return [super methodSignatureForSelector:sel];
    }
    if ([self.delegate respondsToSelector:sel]) {
        return [self.delegate methodSignatureForSelector:sel];
    } else {
        return [super methodSignatureForSelector:sel];
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL action = [invocation selector];
    if ([self isMenuAction:action]) {
        if ([self.delegate respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self.delegate performSelector:action];
#pragma clang diagnostic pop
        }
    } else {
        [super forwardInvocation:invocation];
    }
}

- (UIResponder *)nextResponder {
    return self.delegate;
}

- (void)present:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan && sender.view.userInteractionEnabled) {
		if (self.vibrate) {
			AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
		}
        BOOL shouldPresent = YES;
        if ([self.delegate respondsToSelector:@selector(menuShouldBePresented:)]) {
            shouldPresent = [self.delegate menuShouldBePresented:self];
        }
        if (!shouldPresent) {
            return;
        }
        NSUInteger numberOfItems = self.numberOfItems;
        NSMutableArray* items = [NSMutableArray array];
        for (NSUInteger item = 0; item < numberOfItems; ++item) {
            NSString* title = [self.delegate menu:self titleForItem:item];
            SEL action = [self.delegate menu:self actionForItem:item];
            UIMenuItem* menuItem = [[UIMenuItem alloc] initWithTitle:title action:action];
            if (menuItem) {
                [items addObject:menuItem];
            }
        }
        
        UIMenuController* menuController = [UIMenuController sharedMenuController];
        [self becomeFirstResponder];
        menuController.menuItems = [items copy];
        CGPoint location = [sender locationInView:sender.view];
        [menuController setTargetRect:CGRectMake(location.x, location.y, 0, 0) inView:sender.view];
        [menuController setMenuVisible:YES animated:YES];
	}
}

@end
