//
//  WLKeyboard.m
//  meWrap
//
//  Created by Ravenpod on 24.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLKeyboard.h"

@interface WLKeyboard ()

@property (weak, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation WLKeyboard

+ (instancetype)keyboard {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (void)setup {
    [super setup];
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification*)notification {
    NSDictionary *userInfo = [notification userInfo];
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.height = keyboardSize.height;
    self.duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    self.isShown = YES;
    for (id receiver in [self broadcastReceivers]) {
        if ([receiver respondsToSelector:@selector(keyboardWillShow:)]) {
            [receiver keyboardWillShow:self];
        }
    }
}

- (void)keyboardDidShow:(NSNotification*)notification {
    NSDictionary *userInfo = [notification userInfo];
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.height = keyboardSize.height;
    self.duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    for (id receiver in [self broadcastReceivers]) {
        if ([receiver respondsToSelector:@selector(keyboardDidShow:)]) {
            [receiver keyboardDidShow:self];
        }
    }
	__weak UIWindow* window = [UIWindow mainWindow];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithView:window];
    [tapGestureRecognizer setActionClosure:^(UIGestureRecognizer *sender) {
        [window endEditing:YES];
    }];
    self.tapGestureRecognizer = tapGestureRecognizer;
}

- (void)keyboardWillHide:(NSNotification*)notification {
    NSDictionary *userInfo = [notification userInfo];
    self.duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    for (id receiver in [self broadcastReceivers]) {
        if ([receiver respondsToSelector:@selector(keyboardWillHide:)]) {
            [receiver keyboardWillHide:self];
        }
    }
}

- (void)keyboardDidHide:(NSNotification*)notification {
    self.height = 0;
    self.duration = 0;
    self.curve = 0;
    self.isShown = NO;
    for (id receiver in [self broadcastReceivers]) {
        if ([receiver respondsToSelector:@selector(keyboardDidHide:)]) {
            [receiver keyboardDidHide:self];
        }
    }
    [self.tapGestureRecognizer.view removeGestureRecognizer:self.tapGestureRecognizer];
}

- (void)performAnimation:(WLBlock)animation {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:self.duration];
    [UIView setAnimationCurve:self.curve];
    if (animation) animation();
    [UIView commitAnimations];
}

@end
