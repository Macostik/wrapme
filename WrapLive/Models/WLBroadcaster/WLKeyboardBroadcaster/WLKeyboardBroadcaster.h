//
//  WLKeyboardBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLKeyboardBroadcaster;

@protocol WLKeyboardBroadcastReceiver <WLBroadcastReceiver>

@optional
- (void)broadcaster:(WLKeyboardBroadcaster*)broadcaster willShowKeyboardWithHeight:(NSNumber*)keyboardHeight;
- (void)broadcaster:(WLKeyboardBroadcaster*)broadcaster didShowKeyboardWithHeight:(NSNumber*)keyboardHeight;
- (void)broadcasterWillHideKeyboard:(WLKeyboardBroadcaster*)broadcaster;
- (void)broadcasterDidHideKeyboard:(WLKeyboardBroadcaster*)broadcaster;

@end

@interface WLKeyboardBroadcaster : WLBroadcaster

@end
