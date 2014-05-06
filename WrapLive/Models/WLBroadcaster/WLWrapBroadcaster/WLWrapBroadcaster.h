//
//  WLWrapBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"
#import "WLWrap.h"
#import "WLCandy.h"

@class WLWrapBroadcaster;
@class WLWrap;
@class WLCandy;

@protocol WLWrapBroadcastObject <NSObject>

- (void)broadcastCreation;

- (void)broadcastChange;

- (void)broadcastRemoving;

@end

@protocol WLWrapBroadcastReceiver <WLBroadcastReceiver>

@optional
- (void)broadcaster:(WLWrapBroadcaster*)broadcaster wrapCreated:(WLWrap*)wrap;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster wrapChanged:(WLWrap*)wrap;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster wrapRemoved:(WLWrap*)wrap;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster candyCreated:(WLCandy*)candy;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster candyChanged:(WLCandy*)candy;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster candyRemoved:(WLCandy*)candy;

@end

@interface WLWrapBroadcaster : WLBroadcaster

- (void)broadcastWrapCreation:(WLWrap*)wrap;

- (void)broadcastWrapChange:(WLWrap*)wrap;

- (void)broadcastWrapRemoving:(WLWrap*)wrap;

- (void)broadcastCandyCreation:(WLCandy*)candy;

- (void)broadcastCandyChange:(WLCandy*)candy;

- (void)broadcastCandyRemove:(WLCandy*)candy;

@end

@interface WLWrap (WLWrapBroadcaster) <WLWrapBroadcastObject>

@end

@interface WLCandy (WLWrapBroadcaster) <WLWrapBroadcastObject>

@end
