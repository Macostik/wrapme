//
//  WLWrapPubNubBroadcaster.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLChannelBroadcaster.h"

@class WLWrap;

@class WLWrapChannelBroadcaster;

@protocol WLWrapChannelBroadcastReceiver <NSObject>

@optional

- (void)broadcasterDidAddCandy:(WLWrapChannelBroadcaster*)broadcaster;

- (void)broadcasterDidDeleteCandy:(WLWrapChannelBroadcaster*)broadcaster;

- (void)broadcasterDidAddChatMessage:(WLWrapChannelBroadcaster*)broadcaster;

- (void)broadcasterDidAddComment:(WLWrapChannelBroadcaster*)broadcaster;

- (void)broadcasterDidDeleteComment:(WLWrapChannelBroadcaster*)broadcaster;

@end

@interface WLWrapChannelBroadcaster : WLChannelBroadcaster

@property (strong, nonatomic) WLWrap *wrap;

- (void)addReceiver:(id<WLWrapChannelBroadcastReceiver>)receiver withWrap:(WLWrap*)wrap;

@end
