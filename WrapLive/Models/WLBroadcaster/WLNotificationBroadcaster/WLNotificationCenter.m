//
//  WLPubNubBroadcaster.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLNotificationCenter.h"
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
#import "NSPropertyListSerialization+Shorthand.h"
#import "NSString+Documents.h"

static NSString* WLPubNubOrigin = @"pubsub.pubnub.com";
static NSString* WLPubNubPublishKey = @"pub-c-16ba2a90-9331-4472-b00a-83f01ff32089";
static NSString* WLPubNubSubscribeKey = @"sub-c-bc5bfa70-d166-11e3-8d06-02ee2ddab7fe";
static NSString* WLPubNubSecretKey = @"sec-c-MzYyMTY1YzMtYTZkOC00NzU3LTkxMWUtMzgwYjdkNWNkMmFl";

@interface WLNotificationCenter () <PNDelegate>

@property (strong, nonatomic) WLNotificationChannel* typingChannel;

@property (strong, nonatomic) WLNotificationChannel* userChannel;

@end

@implementation WLNotificationCenter

+ (instancetype)defaultCenter {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (NSMutableOrderedSet *)storedNotifications {
    if (!_storedNotifications) {
        _storedNotifications = [WLNotification notificationsWithDataArray:[NSArray arrayWithContentsOfFile:NSDocumentsDirectoryPath(@"storedNotifications")]];
    }
    return _storedNotifications;
}

- (NSUInteger)unreadNotificationsCount {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"unreadNotificationsCount"];
}

- (void)setUnreadNotificationsCount:(NSUInteger)unreadNotificationsCount {
    [[NSUserDefaults standardUserDefaults] setInteger:unreadNotificationsCount forKey:@"unreadNotificationsCount"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)storeNotification:(WLNotification*)notification {
    if (notification.type == WLNotificationCandyCommentAddition) {
        self.unreadNotificationsCount++;
        [self.storedNotifications insertObject:notification atIndex:0];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveNotifications) object:nil];
        [self performSelector:@selector(saveNotifications) withObject:nil afterDelay:0.5f];
        [self broadcast:@selector(broadcaster:didStoreNotification:) object:notification];
    }
}

- (void)saveNotifications {
    __weak typeof(self)weakSelf = self;
    run_in_background_queue(^{
        NSArray* notifications = [[weakSelf.storedNotifications array] map:^id(WLNotification* notification) {
            return notification.data;
        }];
        [notifications writeToFile:NSDocumentsDirectoryPath(@"storedNotifications") atomically:YES];
    });
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
            [weakSelf storeNotification:notification];
            [weakSelf broadcastNotification:notification];
        }];
    }];
    self.typingChannel = [[WLNotificationChannel alloc] init];
    self.typingChannel.supportPresense = YES;
	[PubNub setupWithConfiguration:[WLNotificationCenter configuration] andDelegate:self];
}

- (void)subscribe {
	NSString* name = [WLUser currentUser].identifier;
	if (!name.nonempty) {
		return;
	}
    [self.userChannel setName:name subscribe:YES];
    [PubNub setClientIdentifier:name];
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
    __weak typeof(self)weakSelf = self;
    WLBroadcastSelectReceiver selectBlock = ^BOOL(NSObject<WLNotificationReceiver> *receiver, id object) {
        if ([receiver respondsToSelector:@selector(broadcaster:shouldReceiveNotification:)]) {
            return [receiver broadcaster:weakSelf shouldReceiveNotification:notification];
        }
        return YES;
    };
    [self broadcast:@selector(broadcaster:notificationReceived:) object:notification select:selectBlock];
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

@implementation WLNotificationCenter (Typing)

- (void)subscribeOnTypingChannel:(WLWrap *)wrap success:(WLBlock)success {
    __weak __typeof(self)weakSelf = self;
    if ([[PubNub sharedInstance] isConnected]) {
        self.typingChannel.name = wrap.identifier;
        [self.typingChannel subscribe:^ {
            [weakSelf fetchParticipants];
            if (success) success();
        } failure:^(NSError *error) {
            [weakSelf subscribeOnTypingChannel:wrap success:success];
        }];
        [self observePresense];
    }
}

- (void)observePresense {
    __weak typeof(self)weakSelf = self;
    [self.typingChannel setPresenseObserver:^(PNPresenceEvent *event) {
        WLUser* user = [WLUser entry:event.client.identifier];
        if ([user isCurrentUser]) {
            return;
        }
        if (event.type == PNPresenceEventStateChanged) {
            [weakSelf handleClientState:event.client.data user:user];
        } else if (event.type == PNPresenceEventTimeout) {
            [weakSelf broadcast:@selector(broadcaster:didEndTyping:) object:user];
        }
    }];

}

- (void)fetchParticipants {
    __weak typeof(self)weakSelf = self;
    [self.typingChannel participants:^(NSArray *participants) {
        for (PNClient* client in participants) {
            WLUser* user = [WLUser entry:client.identifier];
            if ([user isCurrentUser]) {
                continue;
            }
            [weakSelf handleClientState:client.data user:user];
        }
    }];
}

- (void)handleClientState:(NSDictionary*)state user:(WLUser*)user {
    WLNotificationType type = [state[@"action"] integerValue];
    if (type == WLNotificationBeginTyping) {
        [self broadcast:@selector(broadcaster:didBeginTyping:) object:user];
    } else if (type == WLNotificationEndTyping ) {
        [self broadcast:@selector(broadcaster:didEndTyping:) object:user];
    }
}

- (void)unsubscribeFromTypingChannel {
    [self.typingChannel unsubscribe];
}

- (BOOL)isSubscribedOnTypingChannel:(WLWrap *)wrap {
    return self.typingChannel.subscribed && [self.typingChannel.name isEqualToString:wrap.identifier];
}

- (void)sendTypingMessageWithType:(WLNotificationType)type {
    [self.typingChannel changeState:@{@"action" : @(type)}];
}

- (void)beginTyping {
    [self sendTypingMessageWithType:WLNotificationBeginTyping];
}

- (void)endTyping {
    [self sendTypingMessageWithType:WLNotificationEndTyping];
}

@end
