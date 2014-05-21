//
//  WLPubNubBroadcaster.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLNotificationBroadcaster.h"
#import "NSArray+Additions.h"
#import "WLBlocks.h"
#import "WLSession.h"
#import "UIAlertView+Blocks.h"
#import "WLToast.h"
#import "WLUser.h"
#import "NSString+Additions.h"
#import "WLNotification.h"

static NSString* WLPubNubOrigin = @"pubsub.pubnub.com";
static NSString* WLPubNubPublishKey = @"pub-c-16ba2a90-9331-4472-b00a-83f01ff32089";
static NSString* WLPubNubSubscribeKey = @"sub-c-bc5bfa70-d166-11e3-8d06-02ee2ddab7fe";
static NSString* WLPubNubSecretKey = @"sec-c-MzYyMTY1YzMtYTZkOC00NzU3LTkxMWUtMzgwYjdkNWNkMmFl";

@interface WLNotificationBroadcaster () <PNDelegate>

@end

@implementation WLNotificationBroadcaster

+ (instancetype)broadcaster {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

+ (void)enablePushNotificationsInChannels:(NSArray *)channels withDeviceToken:(NSData *)deviceToken {
	[PubNub enablePushNotificationsOnChannels:channels withDevicePushToken:deviceToken];
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

- (void)configure {
	[self connect];
}

- (void)setup {
	[PubNub setupWithConfiguration:[WLNotificationBroadcaster configuration] andDelegate:self];
}

- (void)subscribe {
	NSString* name = [WLUser currentUser].identifier;
	if (!name.nonempty) {
		return;
	}
	PNChannel* channel = [[PubNub subscribedChannels] selectObject:^BOOL(PNChannel* channel) {
		return [channel.name isEqualToString:name];
	}];
	if (!channel) {
		[PubNub subscribeOnChannel:[PNChannel channelWithName:name]];
	}
}

- (void)connect {
	if ([[PubNub sharedInstance] isConnected]) {
		[self subscribe];
	} else {
		__weak typeof(self)weakSelf = self;
		[PubNub connectWithSuccessBlock:^(NSString *state) {
			[weakSelf subscribe];
		} errorBlock:^(PNError *error) {
		}];
	}
}

- (void)handleRemoteNotification:(NSDictionary *)data {
	if (data) {
		self.pendingRemoteNotification = [WLNotification notificationWithData:data];
		if (self.pendingRemoteNotification) {
			[self broadcast:@selector(broadcaster:didReceiveRemoteNotification:) object:self.pendingRemoteNotification];
		}
	}
}

- (void)addReceiver:(id<WLBroadcastReceiver>)receiver {
	[super addReceiver:receiver];
	
	if (self.pendingRemoteNotification && [receiver respondsToSelector:@selector(broadcaster:didReceiveRemoteNotification:)]) {
		[receiver performSelector:@selector(broadcaster:didReceiveRemoteNotification:) withObject:self withObject:self.pendingRemoteNotification];
	}
}

#pragma mark - PNDelegate

- (void)pubnubClient:(PubNub *)client didReceiveMessage:(PNMessage *)message {
	NSLog(@"PubNub message received %@", message);
	WLNotification* notification = [WLNotification notificationWithMessage:message];
	if (notification) {
		NSArray* receivers = [self.receivers copy];
		for (NSObject <WLNotificationReceiver> *receiver in receivers) {
			BOOL shouldReceiveNotification = YES;
			if ([receiver respondsToSelector:@selector(broadcaster:shouldReceiveNotification:)]) {
				shouldReceiveNotification = [receiver broadcaster:self shouldReceiveNotification:notification];
			}
			if (shouldReceiveNotification && [receiver respondsToSelector:@selector(broadcaster:notificationReceived:)]) {
				NSLog(@"PubNub message sent %@", message);
				[receiver broadcaster:self notificationReceived:notification];
			}
		}
	}
}

- (void)pubnubClient:(PubNub *)client didConnectToOrigin:(NSString *)origin {
	NSLog(@"PubNub connected");
}

- (void)pubnubClient:(PubNub *)client connectionDidFailWithError:(PNError *)error {
	NSLog(@"PubNub Error: %@, Connection Failed!", error.localizedDescription);
}

- (void)pubnubClient:(PubNub *)client didSubscribeOnChannels:(NSArray *)channels {
	NSLog(@"PubNub subscribed on channels %@", channels);
	NSData* deviceToken = [WLSession deviceToken];
	if (deviceToken) {
		[WLNotificationBroadcaster enablePushNotificationsInChannels:channels withDeviceToken:deviceToken];
	}
}

- (void)pubnubClient:(PubNub *)client didUnsubscribeOnChannels:(NSArray *)channels {
	NSLog(@"PubNub unsubscribed on channels %@", channels);
}

- (void)pubnubClient:(PubNub *)client didDisconnectFromOrigin:(NSString *)origin withError:(PNError *)error {
	NSLog(@"PubNub will disconnect with error : %@", error);
	[self connect];
}

@end
