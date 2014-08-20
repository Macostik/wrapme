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
#import "WLWrap.h"
#import "WLSoundPlayer.h"
#import "WLNotificationChannel.h"

static NSString* WLPubNubOrigin = @"pubsub.pubnub.com";
static NSString* WLPubNubPublishKey = @"pub-c-16ba2a90-9331-4472-b00a-83f01ff32089";
static NSString* WLPubNubSubscribeKey = @"sub-c-bc5bfa70-d166-11e3-8d06-02ee2ddab7fe";
static NSString* WLPubNubSecretKey = @"sec-c-MzYyMTY1YzMtYTZkOC00NzU3LTkxMWUtMzgwYjdkNWNkMmFl";

@interface WLNotificationBroadcaster () <PNDelegate>

@property (strong, nonatomic) WLNotificationChannel* typingChannel;

@property (strong, nonatomic) WLNotificationChannel* userChannel;

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

static WLDataBlock deviceTokenCompletion = nil;

+ (void)deviceToken:(WLDataBlock)completion {
    NSData* deviceToken = [WLSession deviceToken];
    if (deviceToken) {
        completion(deviceToken);
    } else {
        UIRemoteNotificationType type = UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:type];
        deviceTokenCompletion = completion;
    }
}

+ (void)setDeviceToken:(NSData *)deviceToken {
    [WLSession setDeviceToken:deviceToken];
    if (deviceTokenCompletion) {
        deviceTokenCompletion(deviceToken);
        deviceTokenCompletion = nil;
    }
}

+ (PNConfiguration*)configuration {
	return [PNConfiguration configurationForOrigin:WLPubNubOrigin publishKey:WLPubNubPublishKey subscribeKey:WLPubNubSubscribeKey secretKey:WLPubNubSecretKey];
}

- (void)configure {
	[self performSelector:@selector(connect) withObject:nil afterDelay:0.0f];
    [super configure];
}

- (void)setup {
    [super setup];
    self.userChannel = [[WLNotificationChannel alloc] init];
    self.userChannel.supportAPNS = YES;
    __weak typeof(self)weakSelf = self;
    [self.userChannel setReceive:^(WLNotification *notification) {
        [notification fetch:^{
            if (notification.type == WLNotificationChatCandyAddition) {
                [weakSelf broadcast:@selector(broadcaster:didEndTyping:) object:notification.candy.contributor];
            }
            [WLSoundPlayer play];
        }];
    }];
    self.typingChannel = [[WLNotificationChannel alloc] init];
	[PubNub setupWithConfiguration:[WLNotificationBroadcaster configuration] andDelegate:self];
}

- (void)subscribe {
	NSString* name = [WLUser currentUser].identifier;
	if (!name.nonempty) {
		return;
	}
    [self.userChannel setName:name subscribe:YES];
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

#pragma mark - PNDelegate

- (void)pubnubClient:(PubNub *)client didReceiveMessage:(PNMessage *)message {
	NSLog(@"PubNub message received %@", message);
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

@implementation WLNotificationBroadcaster (Typing)

- (void)subscribeOnTypingChannel:(WLWrap *)wrap success:(WLBlock)success {
    __weak __typeof(self)weakSelf = self;
    if ([[PubNub sharedInstance] isConnected]) {
        self.typingChannel.name = wrap.identifier;
        [self.typingChannel subscribe:success failure:^(NSError *error) {
            [weakSelf subscribeOnTypingChannel:wrap success:success];
        }];
        [self.typingChannel setReceive:^(WLNotification *notification) {
            if (![notification.user isCurrentUser]) {
                if (notification.type == WLNotificationBeginTyping) {
                    [weakSelf broadcast:@selector(broadcaster:didBeginTyping:) object:notification.user];
                } else if (notification.type == WLNotificationEndTyping ) {
                    [weakSelf broadcast:@selector(broadcaster:didEndTyping:) object:notification.user];
                }
            }
        }];
    }
}

- (void)unsubscribeFromTypingChannel {
    [self.typingChannel unsubscribe];
}

- (BOOL)isSubscribedOnTypingChannel:(WLWrap *)wrap {
    return self.typingChannel.subscribed && [self.typingChannel.name isEqualToString:wrap.identifier];
}

- (void)sendTypingMessageWithType:(WLNotificationType)type {
    [self.typingChannel send:@{@"user_uid": [WLUser currentUser].identifier, @"wl_pn_type" : @(type)}];
}

- (void)beginTyping {
    [self sendTypingMessageWithType:WLNotificationBeginTyping];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)applicationWillResignActive {
    [self endTyping];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)applicationDidBecomeActive {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [self beginTyping];
}

- (void)endTyping {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [self sendTypingMessageWithType:WLNotificationEndTyping];
}

@end
