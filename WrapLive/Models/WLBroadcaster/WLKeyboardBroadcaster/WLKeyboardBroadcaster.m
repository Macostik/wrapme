//
//  WLKeyboardBroadcaster.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLKeyboardBroadcaster.h"

@implementation WLKeyboardBroadcaster

+ (instancetype)broadcaster {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self subscribeKeyboardNotifications];
    }
    return self;
}

- (void)subscribeKeyboardNotifications {
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
}

- (void)keyboardWillHide:(NSNotification*)notification {
	[self broadcast:@selector(broadcasterWillHideKeyboard:)];
}

- (void)keyboardDidHide:(NSNotification*)notification {
	[self broadcast:@selector(broadcasterDidHideKeyboard:)];
}

@end
