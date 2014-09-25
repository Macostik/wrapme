//
//  WLWrapBroadcaster.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"
#import "WLEntryManager.h"

@class WLWrapBroadcaster;

@protocol WLWrapBroadcastReceiver

@optional
- (void)broadcaster:(WLWrapBroadcaster*)broadcaster userChanged:(WLUser*)user;

- (WLWrap*)broadcasterPreferedWrap:(WLWrapBroadcaster*)broadcaster;

- (NSInteger)broadcasterPreferedCandyType:(WLWrapBroadcaster*)broadcaster;

- (WLCandy*)broadcasterPreferedCandy:(WLWrapBroadcaster*)broadcaster;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster wrapCreated:(WLWrap*)wrap;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster wrapChanged:(WLWrap*)wrap;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster wrapRemoved:(WLWrap*)wrap;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster candyCreated:(WLCandy*)candy;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster candyChanged:(WLCandy*)candy;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster candyRemoved:(WLCandy*)candy;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster messageCreated:(WLMessage*)message;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster messageChanged:(WLMessage*)message;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster messageRemoved:(WLMessage*)message;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster commentCreated:(WLComment*)comment;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster commentChanged:(WLComment*)comment;

- (void)broadcaster:(WLWrapBroadcaster*)broadcaster commentRemoved:(WLComment*)comment;

@end

@interface WLWrapBroadcaster : WLBroadcaster

- (void)broadcastUserChange:(WLUser *)user;

- (void)broadcastWrapCreation:(WLWrap*)wrap;

- (void)broadcastWrapChange:(WLWrap*)wrap;

- (void)broadcastWrapRemoving:(WLWrap*)wrap;

- (void)broadcastCandyCreation:(WLCandy*)candy;

- (void)broadcastCandyChange:(WLCandy*)candy;

- (void)broadcastCandyRemove:(WLCandy*)candy;

- (void)broadcastMessageCreation:(WLMessage*)message;

- (void)broadcastMessageChange:(WLMessage*)message;

- (void)broadcastMessageRemove:(WLMessage*)message;

- (void)broadcastCommentCreation:(WLComment*)comment;

- (void)broadcastCommentChange:(WLComment*)comment;

- (void)broadcastCommentRemove:(WLComment*)comment;

@end

@interface WLEntry (WLWrapBroadcaster)

@property (readonly, nonatomic) WLEntry* containingEntry;

- (void)broadcastCreation;

- (void)broadcastChange;

- (void)broadcastRemoving;

- (instancetype)update:(NSDictionary*)dictionary;

@end

@interface WLUser (WLWrapBroadcaster) @end

@interface WLWrap (WLWrapBroadcaster) @end

@interface WLCandy (WLWrapBroadcaster) @end

@interface WLMessage (WLWrapBroadcaster) @end

@interface WLComment (WLWrapBroadcaster) @end
