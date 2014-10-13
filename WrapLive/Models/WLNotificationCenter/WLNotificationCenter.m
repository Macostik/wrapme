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
#import "NSDate+Additions.h"
#import "WLAPIRequest.h"
#import "UIDevice+SystemVersion.h"

@interface WLNotificationCenter () <PNDelegate>

@property (strong, nonatomic) WLNotificationChannel* typingChannel;

@property (strong, nonatomic) WLNotificationChannel* userChannel;

@property (strong, nonatomic) NSDate* historyDate;

@end

@implementation WLNotificationCenter

@synthesize historyDate = _historyDate;

+ (instancetype)defaultCenter {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (NSDate *)historyDate {
    if (!_historyDate) _historyDate = [WLSession object:@"historyDate"];
    return _historyDate;
}

- (void)setHistoryDate:(NSDate *)historyDate {
    _historyDate = historyDate;
    [WLSession setObject:historyDate key:@"historyDate"];
}

static WLDataBlock deviceTokenCompletion = nil;

+ (void)deviceToken:(WLDataBlock)completion {
    NSData* deviceToken = [WLSession deviceToken];
    if (deviceToken) {
        completion(deviceToken);
    } else {
        if (SystemVersionGreaterThanOrEqualTo8()) {
            [[UIApplication sharedApplication] registerForRemoteNotifications];
            UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
            UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        } else {
            UIRemoteNotificationType type = UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound;
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:type];
        }
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
    
    NSString* origin, *publishKey, *subscribeKey, *secretKey;
    
    if ([[WLAPIManager instance].environment.name isEqualToString:WLAPIEnvironmentProduction]) {
        origin = @"pubsub.pubnub.com";
        publishKey = @"pub-c-16ba2a90-9331-4472-b00a-83f01ff32089";
        subscribeKey = @"sub-c-bc5bfa70-d166-11e3-8d06-02ee2ddab7fe";
        secretKey = @"sec-c-MzYyMTY1YzMtYTZkOC00NzU3LTkxMWUtMzgwYjdkNWNkMmFl";
    } else {
        origin = @"pubsub.pubnub.com";
        publishKey = @"pub-c-87bbbc30-fc43-4f6b-b1f4-cedd5f30d5e8";
        subscribeKey = @"sub-c-6562fe64-4270-11e4-aed8-02ee2ddab7fe";
        secretKey = @"sec-c-NGE5NWU0NDAtZWMxYS00ZjQzLWJmMWMtZDU5MTE3NWE0YzE0";
    }
    
	return [PNConfiguration configurationForOrigin:origin publishKey:publishKey subscribeKey:subscribeKey secretKey:secretKey];
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
    [self.userChannel setMessageBlock:^(PNMessage *message) {
        WLNotification *notification = [WLNotification notificationWithMessage:message];
        [notification fetch:^{
            if (notification.type  == WLNotificationMessageAdd) {
                WLMessage* message = (id)notification.targetEntry;
                [weakSelf broadcast:@selector(broadcaster:didEndTyping:) object:message.contributor];
            }
            if (notification.playSound) [WLSoundPlayer play];
            [weakSelf broadcastNotification:notification];
        } failure:nil];
        weakSelf.historyDate = [[message.receiveDate date] dateByAddingTimeInterval:NSINTEGER_DEFINED];
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
    [self.userChannel setName:[NSString stringWithFormat:@"%@-%@", name, [WLAuthorization currentAuthorization].deviceUID] subscribe:NO];
    __weak typeof(self)weakSelf = self;
    [self.userChannel subscribe:^{
        [PubNub requestHistoryForChannel:self.userChannel.channel from:[PNDate dateWithDate:weakSelf.historyDate] to:[PNDate dateWithDate:[NSDate date]] includingTimeToken:YES withCompletionBlock:^(NSArray *messages, PNChannel *channel, PNDate *from, PNDate *to, PNError *error) {
            if (!error) {
                if (messages.nonempty) {
                    NSDate *recivedDate = [[[messages.lastObject receiveDate] date] dateByAddingTimeInterval:NSINTEGER_DEFINED];
                    weakSelf.historyDate = recivedDate;
                    for (PNMessage* message in messages) {
                        weakSelf.userChannel.messageBlock(message);
                    }
                }
            }
        }];
    } failure:nil];
    [PubNub setClientIdentifier:name];
}

- (void)connect {
	if ([[PubNub sharedInstance] isConnected]) {
		[self subscribe];
	} else {
		[PubNub connect];
	}
}

- (void)handleRemoteNotification:(NSDictionary *)data success:(WLBlock)success failure:(WLFailureBlock)failure {
    if (!data)  {
        if (failure) failure(nil);
        return;
    }
    switch ([UIApplication sharedApplication].applicationState) {
        case UIApplicationStateActive:
            if (failure) failure(nil);
            break;
        case UIApplicationStateInactive: {
            WLNotification* notification = [WLNotification notificationWithData:data];
            if (notification) {
                self.pendingRemoteNotification = notification;
                __weak typeof(self)weakSelf = self;
                [notification fetch:^{
                    [weakSelf broadcast:@selector(broadcaster:didReceiveRemoteNotification:) object:notification];
                    if (success) success();
                } failure:failure];
            } else if (failure)  {
                failure(nil);
            }
        } break;
        case UIApplicationStateBackground: {
            WLNotification* notification = [WLNotification notificationWithData:data];
            if (notification) {
                [notification fetch:success failure:failure];
            } else if (failure)  {
                failure(nil);
            }
        } break;
        default:
            break;
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

static NSUInteger WLActionBeginTyping = 2000;
static NSUInteger WLActionEndTyping = 2001;

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
    if (type == WLActionBeginTyping) {
        [self broadcast:@selector(broadcaster:didBeginTyping:) object:user];
    } else if (type == WLActionEndTyping ) {
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
    [self sendTypingMessageWithType:WLActionBeginTyping];
}

- (void)endTyping {
    [self sendTypingMessageWithType:WLActionEndTyping];
}

@end
