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

+ (void)enablePushNotifications {
    [self deviceToken:^(NSData *deviceToken) {
        if (![[PubNub sharedInstance] isConnected]) {
            return;
        }
        [PubNub removeAllPushNotificationsForDevicePushToken:deviceToken withCompletionHandlingBlock:^(PNError *error) {
            if (!error) {
                if ([WLUser currentUser].identifier.nonempty) {
                    NSArray* channels = [PubNub subscribedChannels];
                    if (channels && deviceToken && [[PubNub sharedInstance] isConnected]) {
                        [PubNub enablePushNotificationsOnChannels:channels withDevicePushToken:deviceToken];
                    }
                }
            }
        }];
    }];
}

+ (void)disablePushNotifications {
    [WLSession setDeviceToken:nil];
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeNone];
}

static WLDataBlock deviceTokenCompletion = nil;

+ (void)deviceToken:(WLDataBlock)completion {
    NSData* deviceToken = [WLSession deviceToken];
    if (deviceToken) {
        completion(deviceToken);
    } else {
        NSLog(@"registerForRemoteNotificationTypes");
        deviceTokenCompletion = completion;
    }
}

+ (void)setDeviceToken:(NSData *)deviceToken {
    NSLog(@"setDeviceToken");
    [WLSession setDeviceToken:deviceToken];
    if (deviceTokenCompletion) {
        deviceTokenCompletion(deviceToken);
        deviceTokenCompletion = nil;
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
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert |
                                                                          UIRemoteNotificationTypeBadge |
                                                                          UIRemoteNotificationTypeSound];
}

- (void)setup {
    [super setup];
    [self setupMessageSound];
	[PubNub setupWithConfiguration:[WLNotificationBroadcaster configuration] andDelegate:self];
//    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
//        [WLNotificationBroadcaster disablePushNotifications];
//    }];
}

- (void)setupMessageSound {
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"interfacealertsound3" ofType:@"wav"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)([NSURL fileURLWithPath: soundPath]), &soundID);
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

static BOOL isPlayed = NO;

- (void)pubnubClient:(PubNub *)client didReceiveMessage:(PNMessage *)message {
	NSLog(@"PubNub message received %@", message);
	WLNotification* notification = [WLNotification notificationWithMessage:message];
	__weak typeof(self)weakSelf = self;
    [notification fetch:^{
        [weakSelf broadcastNotification:notification];
        if (!isPlayed) {
            isPlayed = YES;
            AudioServicesPlaySystemSound (soundID);
            AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, completionCallback, NULL);
        }
    }];
}

static void completionCallback (SystemSoundID  mySSID, void *myself) {
    isPlayed = NO;
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
	[WLNotificationBroadcaster enablePushNotifications];
}

- (void)pubnubClient:(PubNub *)client didUnsubscribeOnChannels:(NSArray *)channels {
	NSLog(@"PubNub unsubscribed on channels %@", channels);
}

- (void)pubnubClient:(PubNub *)client didDisconnectFromOrigin:(NSString *)origin withError:(PNError *)error {
	NSLog(@"PubNub will disconnect with error : %@", error);
	[self connect];
}

- (void)pubnubClient:(PubNub *)client didEnablePushNotificationsOnChannels:(NSArray *)channels {
    NSLog(@"PubNub didEnablePushNotificationsOnChannels %@", channels);
}

- (void)pubnubClientDidRemovePushNotifications:(PubNub *)client {
    NSLog(@"pubnubClientDidRemovePushNotifications");
}

@end
