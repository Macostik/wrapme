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
#import "NSString+Additions.h"
#import "WLNotification.h"
#import "WLAPIManager.h"
#import "WLAuthorization.h"
#import "WLEntryManager.h"
#import <AudioToolbox/AudioToolbox.h>

static NSString* WLPubNubOrigin = @"pubsub.pubnub.com";
static NSString* WLPubNubPublishKey = @"pub-c-16ba2a90-9331-4472-b00a-83f01ff32089";
static NSString* WLPubNubSubscribeKey = @"sub-c-bc5bfa70-d166-11e3-8d06-02ee2ddab7fe";
static NSString* WLPubNubSecretKey = @"sec-c-MzYyMTY1YzMtYTZkOC00NzU3LTkxMWUtMzgwYjdkNWNkMmFl";

@interface WLNotificationBroadcaster () <PNDelegate>
{
    SystemSoundID soundID;
}

@property (strong, nonatomic) NSDate* date;

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
	if (channels && deviceToken && [[PubNub sharedInstance] isConnected]) {
		[PubNub enablePushNotificationsOnChannels:channels withDevicePushToken:deviceToken];
	}
}

+ (void)enablePushNotificationsInSubscribedChannels:(NSData *)deviceToken {
    if ([WLUser currentUser].identifier.nonempty && [[PubNub sharedInstance] isConnected]) {
        [self enablePushNotificationsInChannels:[PubNub subscribedChannels] withDeviceToken:deviceToken];
    }
}

+ (PNConfiguration*)configuration {
	return [PNConfiguration configurationForOrigin:WLPubNubOrigin
										publishKey:WLPubNubPublishKey
									  subscribeKey:WLPubNubSubscribeKey
										 secretKey:WLPubNubSecretKey];
}

- (void)configure {
	[self performSelector:@selector(connect) withObject:nil afterDelay:0.0f];
    [super configure];
}

- (void)setup {
    [super setup];
    [self setupMessageSound];
	[PubNub setupWithConfiguration:[WLNotificationBroadcaster configuration] andDelegate:self];
}

- (void)setupMessageSound {
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"triade" ofType:@"aif"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)([NSURL fileURLWithPath: soundPath]), &soundID);
}

- (NSDate *)date {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"pubnub_history_date"];
}

- (void)setDate:(NSDate *)date {
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:@"pubnub_history_date"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)subscribe {
	NSString* name = [WLUser currentUser].identifier;
	if (!name.nonempty) {
		return;
	}
    [PubNub subscribeOnChannel:[PNChannel channelWithName:name]];
}

- (void)connect {
	if ([[PubNub sharedInstance] isConnected]) {
		[self subscribe];
	} else {
		[PubNub connect];
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

- (void)addReceiver:(id)receiver {
	[super addReceiver:receiver];
	if (self.pendingRemoteNotification && [receiver respondsToSelector:@selector(broadcaster:didReceiveRemoteNotification:)]) {
		[receiver broadcaster:self didReceiveRemoteNotification:self.pendingRemoteNotification];
	}
}

- (void)broadcastNotification:(WLNotification*)notification {
    [self broadcast:@selector(broadcaster:notificationReceived:) object:notification select:^BOOL(NSObject<WLNotificationReceiver> *receiver) {
        if ([receiver respondsToSelector:@selector(broadcaster:shouldReceiveNotification:)]) {
            return [receiver broadcaster:self shouldReceiveNotification:notification];
        }
        return YES;
    }];
}

#pragma mark - PNDelegate

- (void)pubnubClient:(PubNub *)client didReceiveMessage:(PNMessage *)message {
	NSLog(@"PubNub message received %@", message);
	WLNotification* notification = [WLNotification notificationWithMessage:message];
	__weak typeof(self)weakSelf = self;
    [notification fetch:^{
        [weakSelf broadcastNotification:notification];

        AudioServicesPlaySystemSound (soundID);
    }];
    self.date = [NSDate date];
}

- (void)pubnubClient:(PubNub *)client didConnectToOrigin:(NSString *)origin {
	NSLog(@"PubNub connected");
    [self subscribe];
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
//    PNChannel* channel = [channels lastObject];
//    PNDate* date = [PNDate dateWithDate:self.date];
//    if (channel && date) {
//        [PubNub requestHistoryForChannel:channel from:date];
//    }
    self.date = [NSDate date];
}

- (void)pubnubClient:(PubNub *)client didUnsubscribeOnChannels:(NSArray *)channels {
	NSLog(@"PubNub unsubscribed on channels %@", channels);
}

- (void)pubnubClient:(PubNub *)client didDisconnectFromOrigin:(NSString *)origin withError:(PNError *)error {
	NSLog(@"PubNub will disconnect with error : %@", error);
	[self connect];
}

@end
