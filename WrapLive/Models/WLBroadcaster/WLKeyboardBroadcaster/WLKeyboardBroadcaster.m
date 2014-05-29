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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification*)notification {
	CGFloat keyboardHeight = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
	[self broadcast:@selector(broadcaster:willShowKeyboardWithHeight:) object:@(keyboardHeight)];
}

- (void)keyboardDidShow:(NSNotification*)notification {
	CGFloat keyboardHeight = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
	[self broadcast:@selector(broadcaster:didShowKeyboardWithHeight:) object:@(keyboardHeight)];
	__weak UIWindow* window = [UIWindow mainWindow];
	[window addTapGestureRecognizing:^(CGPoint point){
		[window endEditing:YES];
	}];
}

- (void)keyboardWillHide:(NSNotification*)notification {
	[self broadcast:@selector(broadcasterWillHideKeyboard:)];
}

- (void)keyboardDidHide:(NSNotification*)notification {
	[self broadcast:@selector(broadcasterDidHideKeyboard:)];
	[[UIWindow mainWindow] removeTapGestureRecognizing];
}

@end
