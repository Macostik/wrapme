//
//  WLPubNubBroadcaster.m
//  meWrap
//
//  Created by Ravenpod on 5/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationCenter.h"
#import "NSArray+WLCollection.h"

@interface NSData (DeviceTokenSerialization)

- (NSString *)serializeDevicePushToken;

@end

@implementation NSData (DeviceTokenSerialization)

- (NSString *)serializeDevicePushToken {
    
    NSUInteger capacity = [self length];
    NSMutableString *stringBuffer = [[NSMutableString alloc] initWithCapacity:capacity];
    const unsigned char *dataBuffer = [self bytes];
    
    // Iterate over the bytes
    for (NSUInteger i=0; i < [self length]; i++) {
        
        [stringBuffer appendFormat:@"%02.2hhX", dataBuffer[i]];
    }
    
    
    return [stringBuffer copy];
}

@end

@interface WLNotificationCenter () <PNObjectEventListener, EntryNotifying, NotificationSubscriptionDelegate>

@property (strong, nonatomic) NotificationSubscription* userSubscription;

@property (strong, nonatomic) NSMutableArray* enqueuedMessages;

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

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
        __weak typeof(self)weakSelf = self;
        [[Dispatch mainQueue] after:0.2 block:^{
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                [weakSelf performSelector:@selector(requestHistory) withObject:nil afterDelay:0.5f];
            }];
        }];
    }
    return self;
}

- (void)configure {
    [[User notifier] addReceiver:self];
}

- (void)setup {
    self.enqueuedMessages = [NSMutableArray array];
    [[PubNub sharedInstance] addListener:self];
}

- (void)subscribe {
    [self subscribeWithUser:[User currentUser]];
}

- (void)subscribeWithUser:(User *)user {
    NSString* uuid = user.uid;
    if (!uuid.nonempty) {
        return;
    }
    NSString *channelName = [NSString stringWithFormat:@"cg-%@", uuid];
    if (![self.userSubscription.name isEqualToString:channelName]) {
        self.userSubscription = [[NotificationSubscription alloc] initWithName:channelName isGroup:YES observePresence:YES];
        self.userSubscription.delegate = self;
        
        if (self.pushToken) {
            if ([Authorization active]) {
                [[APIRequest updateDevice] send];
            }
        } else {
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
    }
    [self.userSubscription subscribe];
}

- (void)handleDeviceToken:(NSData*)deviceToken {
    self.pushToken = deviceToken;
    self.pushTokenString = [deviceToken serializeDevicePushToken];
    if ([Authorization active]) {
        [[APIRequest updateDevice] send];
    }
}

- (void)handleRemoteNotification:(NSDictionary *)data success:(void(^)(Notification *notification))success failure:(FailureBlock)failure {
    if (!data)  {
        if (failure) failure(nil);
        return;
    }
    __weak typeof(self)weakSelf = self;
    Notification* notification = [Notification notificationWithBody:data publishedAt:nil];
    [Logger log:[NSString stringWithFormat:@"PUBNUB - received APNS: %@", data]];
    if (notification) {
        if ([self canSkipNotification:notification]) {
            if (success) success(notification);
        } else {
            [[RunQueue fetchQueue] run:^(Block finish) {
                [EntryContext.sharedContext assureSave:^{
                    if (!notification) {
                        finish();
                        return;
                    }
                    [notification handle:^ {
                        [weakSelf addHandledNotifications:@[notification]];
                        if (success) success(notification);
                        finish();
                    } failure:^(NSError *error) {
                        if (failure) failure(error);
                        finish();
                    }];
                }];
            }];
        }
    } else {
        if (failure) failure([[NSError alloc] initWithMessage:@"Data in remote notification is not valid."]);
    }
}

// MARK: - NotificationSubscriptionDelegate

- (void)fetchLiveBroadcasts:(void (^)(void))completionHandler {
    [[PubNub sharedInstance] hereNowForChannelGroup:self.userSubscription.name withCompletion:^(PNPresenceChannelGroupHereNowResult *result, PNErrorStatus *status) {
        NSDictionary *channels = result.data.channels;
        for (NSString *channel in channels) {
            Wrap *wrap = [Wrap entry:channel];
            if (wrap == nil) {
                continue;
            }
            NSArray *uuids = channels[channel][@"uuids"];
            NSMutableArray *wrapBroadcasts = [NSMutableArray array];
            for (NSDictionary *uuid in uuids) {
                NSDictionary *state = uuid[@"state"];
                User *user = [User entry:state[@"userUid"]];
                if (user == nil) {
                    continue;
                }
                NSString *streamName = state[@"streamName"];
                if (streamName != nil) {
                    LiveBroadcast *broadcast = [[LiveBroadcast alloc] init];
                    broadcast.broadcaster = user;
                    broadcast.wrap = wrap;
                    broadcast.title = state[@"title"];
                    broadcast.streamName = streamName;
                    [wrapBroadcasts addObject:broadcast];
                }
                [user fetchIfNeeded:nil failure:nil];
            }
            wrap.liveBroadcasts = [wrapBroadcasts copy];
        }
        completionHandler();
    }];
}

- (void)notificationSubscription:(NotificationSubscription *)subscription didReceivePresenceEvent:(PNPresenceEventResult * _Nonnull)event {
    Wrap *wrap = [Wrap entry:event.data.actualChannel];
    NSDictionary *state = event.data.presence.state;
    User *user = [User entry:state[@"userUid"]];
    if (wrap && user) {
        if ([event.data.presenceEvent isEqualToString:@"state-change"]) {
            [user fetchIfNeeded:^(id  _Nullable object) {
                if ([event.data.presence.uuid isEqualToString:[User channelName]]) {
                    return;
                }
                NSString *streamName = state[@"streamName"];
                if (streamName != nil) {
                    LiveBroadcast *broadcast = [[LiveBroadcast alloc] init];
                    broadcast.broadcaster = user;
                    broadcast.wrap = wrap;
                    broadcast.title = state[@"title"];
                    broadcast.streamName = streamName;
                    [wrap addBroadcast:broadcast];
                } else {
                    for (LiveBroadcast *broadcast in wrap.liveBroadcasts) {
                        if (broadcast.broadcaster == user) {
                            [wrap removeBroadcast:broadcast];
                            break;
                        }
                    }
                }
            } failure:nil];
        } else if ([event.data.presenceEvent isEqualToString:@"timeout"]) {
            if ([event.data.presence.uuid isEqualToString:[User channelName]]) {
                return;
            }
            NSString *streamName = state[@"streamName"];
            if (streamName == nil) {
                for (LiveBroadcast *broadcast in wrap.liveBroadcasts) {
                    if (broadcast.broadcaster == user) {
                        [wrap removeBroadcast:broadcast];
                        break;
                    }
                }
            }
        }
    }
}

- (void)notificationSubscription:(NotificationSubscription *)subscription didReceiveMessage:(PNMessageResult * _Nonnull)message {
    NSLog(@"notificationSubscription:didReceiveMessage:");
    [self.enqueuedMessages addObject:message.data];
    [self enqueueSelector:@selector(handleEnqueuedMessages)];
}

- (void)handleEnqueuedMessages {
    NSArray *notifications = [self notificationsFromMessages:self.enqueuedMessages];
    [self.enqueuedMessages removeAllObjects];
    if (notifications.nonempty) {
        NSMutableIndexSet *playedSoundTypes = [NSMutableIndexSet indexSet];
        
        for (Notification *notification in notifications) {
            [[RunQueue fetchQueue] run:^(Block finish) {
                if (!notification) {
                    finish();
                    return;
                }
                [notification fetch:^{
                    if (![playedSoundTypes containsIndex:notification.soundType]) [[SoundPlayer player] playForNotification:notification];
                    [playedSoundTypes addIndex:notification.soundType];
                    finish();
                } failure:^(NSError *error) {
                    finish();
                }];
            }];
            [Logger log:[NSString stringWithFormat:@"PUBNUB - direct message received %@", notification]];
        }
        
        [[RunQueue fetchQueue] run:^(Block finish) {
            for (Notification *notification in notifications) {
                [notification submit];
            }
            finish();
        }];
    }
}

- (void)clear {
    self.userSubscription = nil;
    [[NSUserDefaults standardUserDefaults] clearHandledNotifications];
    [NSUserDefaults standardUserDefaults].historyDate = nil;
    [PubNub setSharedInstance:nil];
}

- (void)requestHistory {
    __weak typeof(self)weakSelf = self;
    [[RunQueue fetchQueue] run:^(Block finish) {
        NSDate *historyDate = [NSUserDefaults standardUserDefaults].historyDate;
        if (historyDate) {
            NSDate *fromDate = historyDate;
            NSDate *toDate = [NSDate now];

            [Logger log:[NSString stringWithFormat:@"PUBNUB - requesting history starting from: %@ to: %@", fromDate, toDate]];
            
            if  ([Network sharedNetwork].reachable && weakSelf.userSubscription) {
                
                [weakSelf.userSubscription history:fromDate to:toDate success:^(NSArray *messages) {
                    if (messages.count > 0) {
                        [Logger log:[NSString stringWithFormat:@"PUBNUB - received history starting from: %@ to: %@", fromDate, toDate]];
                        [weakSelf handleHistoryMessages:messages];
                        [NSUserDefaults standardUserDefaults].historyDate = [[NSDate dateWithTimetoken:[(NSDictionary*)[messages lastObject] numberForKey:@"timetoken"]] dateByAddingTimeInterval:0.001];
                        [weakSelf requestHistory];
                    } else {
                        [Logger log:[NSString stringWithFormat:@"PUBNUB - no missed messages in history"]];
                        [NSUserDefaults standardUserDefaults].historyDate = toDate;
                    }
                    finish();
                } failure:^(NSError *error) {
                    finish();
                }];
            } else {
                finish();
            }
        } else {
            [Logger log:[NSString stringWithFormat:@"PUBNUB - history date is empty"]];
            [NSUserDefaults standardUserDefaults].historyDate = [NSDate now];
            finish();
        }
    }];
}

- (void)handleHistoryMessages:(NSArray*)messages {
    NSArray *notifications = [self notificationsFromMessages:messages];
    if (notifications.nonempty) {
        
        NSMutableIndexSet *playedSoundTypes = [NSMutableIndexSet indexSet];
        
        for (Notification *notification in notifications) {
            [[RunQueue fetchQueue] run:^(Block finish) {
                if (!notification) {
                    finish();
                    return;
                }
                [notification fetch:^{
                    if (![playedSoundTypes containsIndex:notification.soundType]) [[SoundPlayer player] playForNotification:notification];
                    [playedSoundTypes addIndex:notification.soundType];
                    finish();
                } failure:^(NSError *error) {
                    finish();
                }];
            }];
            [Logger log:[NSString stringWithFormat:@"PUBNUB - history message received %@", notification]];
        }
        
        [[RunQueue fetchQueue] run:^(Block finish) {
            for (Notification *notification in notifications) {
                [notification submit];
            }
            finish();
        }];
    }
}

#pragma mark - PNObjectEventListener

- (void)client:(PubNub *)client didReceiveMessage:(PNMessageResult *)message {
#if DEBUG
    [Logger log:[NSString stringWithFormat:@"listener didReceiveMessage %@", message.data.message]];
#else
    [Logger log:[NSString stringWithFormat:@"PUBNUB - did receive message"]];
#endif
}

- (void)client:(PubNub *)client didReceivePresenceEvent:(PNPresenceEventResult *)event {
    [Logger log:[NSString stringWithFormat:@"PUBNUB - did receive presence event: %@", event.data.presenceEvent]];
}

- (void)client:(PubNub *)client didReceiveStatus:(PNSubscribeStatus *)status {
    [Logger log:[NSString stringWithFormat:@"PUBNUB - subscribtion status: %@", status.debugDescription]];
    if (status.category == PNConnectedCategory) {
        if (status.subscribedChannelGroups.count > 0) {
            [self requestHistory];
        }
    }
}

// MARK: - EntryNotifying

- (void)notifier:(EntryNotifier *)notifier didAddEntry:(Entry *)entry {
    [self subscribeWithUser:(User *)entry];
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return [User currentUser] == entry;
}

@end
