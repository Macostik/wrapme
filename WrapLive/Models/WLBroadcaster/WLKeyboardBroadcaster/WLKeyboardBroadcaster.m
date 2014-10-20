//
//  WLKeyboardBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLKeyboardBroadcaster.h"
#import "UIView+GestureRecognizing.h"
#import "WLSupportFunctions.h"
#import "WLNavigation.h"
#import "UIView+AnimationHelper.h"

@interface WLKeyboardBroadcaster ()

@end

@implementation WLKeyboardBroadcaster

+ (instancetype)broadcaster {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (void)setup {
    [super setup];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification*)notification {
	CGFloat keyboardHeight = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    self.keyboardHeight = @(keyboardHeight);
    self.duration = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    self.animationCurve = [[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	[self broadcast:@selector(broadcaster:willShowKeyboardWithHeight:) object:self.keyboardHeight];
}

- (void)keyboardDidShow:(NSNotification*)notification {
	CGFloat keyboardHeight = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    self.keyboardHeight = @(keyboardHeight);
    self.duration = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    self.animationCurve = [[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	[self broadcast:@selector(broadcaster:didShowKeyboardWithHeight:) object:self.keyboardHeight];
	__weak UIWindow* window = [UIWindow mainWindow];
	[window addTapGestureRecognizing:^(UIGestureRecognizer *recognizer){
		[window endEditing:YES];
	}];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    self.keyboardHeight = nil;
    self.duration = [[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    self.animationCurve = [[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	[self broadcast:@selector(broadcasterWillHideKeyboard:)];
}

- (void)keyboardDidHide:(NSNotification*)notification {
    self.keyboardHeight = nil;
    self.duration = nil;
    self.animationCurve = nil;
	[self broadcast:@selector(broadcasterDidHideKeyboard:)];
	[[UIWindow mainWindow] removeTapGestureRecognizing];
}

- (void)performAnimation:(WLBlock)animation {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[self.duration doubleValue]];
    [UIView setAnimationCurve:[self.animationCurve integerValue]];
    if (animation) animation();
    [UIView commitAnimations];
}

@end
