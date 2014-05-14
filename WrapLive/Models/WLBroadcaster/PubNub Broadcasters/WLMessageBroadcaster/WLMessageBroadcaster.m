//
//  WLPubNubBroadcaster.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLMessageBroadcaster.h"
#import "NSObject+AssociatedObjects.h"
#import "NSArray+Additions.h"
#import "WLBlocks.h"
#import "WLSession.h"

static NSString* WLPubNubOrigin = @"pubsub.pubnub.com";
static NSString* WLPubNubPublishKey = @"pub-c-16ba2a90-9331-4472-b00a-83f01ff32089";
static NSString* WLPubNubSubscribeKey = @"sub-c-bc5bfa70-d166-11e3-8d06-02ee2ddab7fe";
static NSString* WLPubNubSecretKey = @"sec-c-MzYyMTY1YzMtYTZkOC00NzU3LTkxMWUtMzgwYjdkNWNkMmFl";

@interface PNChannel (WLChannelBroadcaster)

@property (nonatomic) NSInteger subscriptionsCount;

@end

@implementation PNChannel (WLChannelBroadcaster)

- (void)setSubscriptionsCount:(NSInteger)subscriptionsCount {
	[self setAssociatedObject:@(subscriptionsCount) forKey:"wl_subscriptionsCount"];
}

- (NSInteger)subscriptionsCount {
	return [[self associatedObjectForKey:"wl_subscriptionsCount"] integerValue];
}

@end

@interface WLMessageBroadcaster () <PNDelegate>

@end

@implementation WLMessageBroadcaster

+ (instancetype)broadcaster {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

+ (void)enablePushNotificationsInChannels:(NSArray *)channels withDeviceToken:(NSData *)deviceToken {
	for (PNChannel* channel in channels) {
		[PubNub enablePushNotificationsOnChannel:channel withDevicePushToken:deviceToken];
	}
}

+ (void)enablePushNotificationsInSubscribedChannels:(NSData *)deviceToken {
	[self enablePushNotificationsInChannels:[PubNub subscribedChannels] withDeviceToken:deviceToken];
}

+ (PNConfiguration*)configuration {
	return [PNConfiguration configurationForOrigin:WLPubNubOrigin
										publishKey:WLPubNubPublishKey
									  subscribeKey:WLPubNubSubscribeKey
										 secretKey:WLPubNubSecretKey];
}

- (void)setup {
	[PubNub setupWithConfiguration:[WLMessageBroadcaster configuration] andDelegate:self];
}

- (void)addReceiver:(id<WLMessageBroadcastReceiver>)receiver {
	[super addReceiver:receiver];
	[self subscribe:receiver];
}

- (void)subscribe:(id<WLMessageBroadcastReceiver>)receiver {
	__weak typeof(self)weakSelf = self;
	__weak typeof(receiver)weakReceiver = receiver;
	WLBlock subscribingBlock = ^{
		NSString* name = [weakReceiver broadcasterChannelName:weakSelf];
		PNChannel* channel = [[PubNub subscribedChannels] selectObject:^BOOL(PNChannel* channel) {
			return [channel.name isEqualToString:name];
		}];
		if (!channel) {
			channel = [PNChannel channelWithName:name];
			[PubNub subscribeOnChannel:channel];
		}
		channel.subscriptionsCount = channel.subscriptionsCount + 1;
	};
	
	if ([[PubNub sharedInstance] isConnected]) {
		subscribingBlock();
	} else {
		[PubNub connectWithSuccessBlock:^(NSString *state) {
			subscribingBlock();
		} errorBlock:^(PNError *error) {
		}];
	}
}

- (void)unsubscribe:(id<WLMessageBroadcastReceiver>)receiver {
	NSString* name = [receiver broadcasterChannelName:self];
	
	PNChannel* channel = [[PubNub subscribedChannels] selectObject:^BOOL(PNChannel* channel) {
		return [channel.name isEqualToString:name];
	}];
	
	NSInteger subscriptionsCount = channel.subscriptionsCount;
	subscriptionsCount = MAX(0, subscriptionsCount - 1);
	channel.subscriptionsCount = subscriptionsCount;
	if (channel && subscriptionsCount == 0) {
		[PubNub unsubscribeFromChannel:channel withCompletionHandlingBlock:^(NSArray *channels, PNError *error) {
		}];
	}
}

#pragma mark - PNDelegate

- (void)pubnubClient:(PubNub *)client didReceiveMessage:(PNMessage *)message {
	NSLog(@"message %@", message);
	NSHashTable* receivers = [self.receivers copy];
	for (id<WLMessageBroadcastReceiver> receiver in receivers) {
		if ([[receiver broadcasterChannelName:self] isEqualToString:message.channel.name]) {
			if ([receiver respondsToSelector:@selector(broadcaster:messageReceived:)]) {
				[receiver broadcaster:self messageReceived:message];
			}
		}
	}
}

- (void)pubnubClient:(PubNub *)client didConnectToOrigin:(NSString *)origin {
	
}

- (void)pubnubClient:(PubNub *)client connectionDidFailWithError:(PNError *)error {
	NSLog(@"DELEGATE: Error: %@, Connection Failed!", error.localizedDescription);
}

- (void)pubnubClient:(PubNub *)client didSubscribeOnChannels:(NSArray *)channels {
	NSLog(@"subscribed on Channels %@", channels);
	NSData* deviceToken = [WLSession deviceToken];
	if (deviceToken) {
		[WLMessageBroadcaster enablePushNotificationsInChannels:channels withDeviceToken:deviceToken];
	}
}

- (void)pubnubClient:(PubNub *)client didUnsubscribeOnChannels:(NSArray *)channels {
	NSLog(@"unsubscribed on Channels %@", channels);
}

- (void)pubnubClient:(PubNub *)client willDisconnectWithError:(PNError *)error {
	NSLog(@"PubNub willDisconnectWithError : %@ ", [PubNub subscribedChannels]);
	[PubNub connect];
}

@end
