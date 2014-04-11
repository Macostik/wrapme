//
//  WLWrapBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLWrapBroadcaster;
@class WLWrap;

@protocol WLWrapBroadcastReceiver <NSObject>

@optional
- (void)wrapBroadcaster:(WLWrapBroadcaster*)broadcaster wrapChanged:(WLWrap*)wrap;
- (void)wrapBroadcaster:(WLWrapBroadcaster*)broadcaster wrapCreated:(WLWrap*)wrap;

@end

@interface WLWrapBroadcaster : NSObject

+ (instancetype)broadcaster;

- (void)addReceiver:(id <WLWrapBroadcastReceiver>)receiver;

- (BOOL)containsReceiver:(id <WLWrapBroadcastReceiver>)receiver;

- (void)broadcastChange:(WLWrap*)wrap;

- (void)broadcastCreation:(WLWrap*)wrap;

@end
