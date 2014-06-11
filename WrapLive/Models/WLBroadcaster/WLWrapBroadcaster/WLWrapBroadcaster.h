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
#import "WLComment.h"

@class WLWrapBroadcaster;

@protocol WLWrapBroadcastObject <NSObject>

- (void)broadcastCreation;

- (void)broadcastChange;

- (void)broadcastRemoving;

@end

@protocol WLWrapBroadcastReceiver <WLBroadcastReceiver>

@optional
- (WLWrap*)broadcasterPreferedWrap:(WLWrapBroadcaster*)broadcaster;

- (WLCandy*)broadcasterPreferedCandy:(WLWrapBroadcaster*)broadcaster;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster wrapCreated:(WLWrap*)wrap;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster wrapChanged:(WLWrap*)wrap;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster wrapRemoved:(WLWrap*)wrap;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster candyCreated:(WLCandy*)candy;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster candyChanged:(WLCandy*)candy;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster candyRemoved:(WLCandy*)candy;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster commentCreated:(WLComment*)comment;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster commentChanged:(WLComment*)comment;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster commentRemoved:(WLComment*)comment;

@end

@interface WLWrapBroadcaster : WLBroadcaster

- (void)broadcastWrapCreation:(WLWrap*)wrap;

- (void)broadcastWrapChange:(WLWrap*)wrap;

- (void)broadcastWrapRemoving:(WLWrap*)wrap;

- (void)broadcastCandyCreation:(WLCandy*)candy;

- (void)broadcastCandyChange:(WLCandy*)candy;

- (void)broadcastCandyRemove:(WLCandy*)candy;

- (void)broadcastCommentCreation:(WLComment*)comment;

- (void)broadcastCommentChange:(WLComment*)comment;

- (void)broadcastCommentRemove:(WLComment*)comment;

@end

@interface WLEntry (WLWrapBroadcaster) <WLWrapBroadcastObject> @end

@interface WLWrap (WLWrapBroadcaster) @end

@interface WLCandy (WLWrapBroadcaster) @end

@interface WLComment (WLWrapBroadcaster) @end
