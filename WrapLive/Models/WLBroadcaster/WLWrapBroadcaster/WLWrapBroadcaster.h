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
@class WLCandy;

@protocol WLWrapBroadcastReceiver <WLBroadcastReceiver>

@optional
- (void)broadcaster:(WLWrapBroadcaster*)broadcaster wrapChanged:(WLWrap*)wrap;
- (void)broadcaster:(WLWrapBroadcaster*)broadcaster wrapCreated:(WLWrap*)wrap;
- (void)broadcaster:(WLWrapBroadcaster*)broadcaster candyChanged:(WLCandy*)candy;

@end

@interface WLWrapBroadcaster : WLBroadcaster

- (void)broadcastChange:(WLWrap*)wrap;

- (void)broadcastCreation:(WLWrap*)wrap;

- (void)broadcastCandyChange:(WLCandy*)candy;

@end
