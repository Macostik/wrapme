//
//  WLKeyboard.h
//  meWrap
//
//  Created by Ravenpod on 24.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
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
@property (nonatomic) BOOL isShown;

+ (instancetype)keyboard;

- (void)performAnimation:(WLBlock)animation;

@end
