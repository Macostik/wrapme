//
//  WLWrapPubNubBroadcaster.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLChannelBroadcaster.h"

@class WLWrap;
@class WLCandy;

@class WLWrapChannelBroadcaster;

@protocol WLWrapChannelBroadcastReceiver <WLBroadcastReceiver>

@optional

- (void)broadcaster:(WLWrapChannelBroadcaster*)broadcaster didAddCandy:(WLCandy*)candy;

- (void)broadcaster:(WLWrapChannelBroadcaster*)broadcaster didDeleteCandy:(WLCandy*)candy;

- (void)broadcaster:(WLWrapChannelBroadcaster*)broadcaster didAddChatMessage:(WLCandy*)message;

- (void)broadcaster:(WLWrapChannelBroadcaster*)broadcaster didAddComment:(WLCandy*)candy;

- (void)broadcaster:(WLWrapChannelBroadcaster*)broadcaster didDeleteComment:(WLCandy*)candy;

@end

@interface WLWrapChannelBroadcaster : WLChannelBroadcaster

@property (strong, nonatomic) WLWrap *wrap;

@property (strong, nonatomic) WLCandy *candy;

- (instancetype)initWithReceiver:(id<WLWrapChannelBroadcastReceiver>)receiver wrap:(WLWrap*)wrap;

- (void)addReceiver:(id<WLWrapChannelBroadcastReceiver>)receiver withWrap:(WLWrap*)wrap;

@end
