//
//  WLWrapBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLWrapBroadcaster;
@class WLWrap;

@protocol WLWrapBroadcastReceiver <WLBroadcastReceiver>

@optional
- (void)broadcaster:(WLWrapBroadcaster*)broadcaster wrapChanged:(WLWrap*)wrap;
- (void)broadcaster:(WLWrapBroadcaster*)broadcaster wrapCreated:(WLWrap*)wrap;

@end

@interface WLWrapBroadcaster : WLBroadcaster

- (void)broadcastChange:(WLWrap*)wrap;

- (void)broadcastCreation:(WLWrap*)wrap;

@end
