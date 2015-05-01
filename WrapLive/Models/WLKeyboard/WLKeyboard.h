//
//  WLKeyboard.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLKeyboard;

@protocol WLKeyboardBroadcastReceiver

@optional
- (void)keyboardWillShow:(WLKeyboard*)keyboard;
- (void)keyboardDidShow:(WLKeyboard*)keyboard;
- (void)keyboardWillHide:(WLKeyboard*)keyboard;
- (void)keyboardDidHide:(WLKeyboard*)keyboard;

@end

@interface WLKeyboard : WLBroadcaster

@property (nonatomic) CGFloat height;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSUInteger curve;
@property (nonatomic) BOOL isShow;

+ (instancetype)keyboard;

- (void)performAnimation:(WLBlock)animation;

@end
