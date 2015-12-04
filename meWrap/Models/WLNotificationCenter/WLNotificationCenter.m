//
//  WLPubNubBroadcaster.m
//  meWrap
//
//  Created by Ravenpod on 5/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationCenter.h"
#import "WLSoundPlayer.h"
#import "WLOperationQueue.h"
#import "WLNotification.h"
#import "WLNetwork.h"
#import "WLAuthorizationRequest.h"

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
        run_after(0.2, ^{
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                [weakSelf performSelector:@selector(requestHistory) withObject:nil afterDelay:0.5f];
            }];
        });
        
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
    if ([self.userSubscription.name isEqualToString:channelName]) {
        [self.userSubscription subscribe];
    } else {
        self.userSubscription = [[NotificationSubscription alloc] initWithName:channelName isGroup:YES observePresence:YES];
        self.userSubscription.delegate = self;
        
        if (self.pushToken) {
            if ([WLAuthorizationRequest authorized]) {
                [[WLAuthorizationRequest updateDevice] send];
            }
        } else {
            [self registerForRemoteNotifications];
        }
    }
}

- (void)registerForRemoteNotifications {
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)handleDeviceToken:(NSData*)deviceToken {
    self.pushToken = deviceToken;
    self.pushTokenString = [deviceToken serializeDevicePushToken];
    if ([WLAuthorizationRequest authorized]) {
        [[WLAuthorizationRequest updateDevice] send];
    }
}

- (void)handleRemoteNotification:(NSDictionary *)data success:(ObjectBlock)success failure:(FailureBlock)failure {
    if (!data)  {
        if (failure) failure(nil);
        return;
    }
    __weak typeof(self)weakSelf = self;
    WLNotification* notification = [WLNotification notificationWithData:data];
    WLLog(@"PUBNUB - received APNS: %@", data);
    if (notification) {
        if ([self isAlreadyHandledNotification:notification]) {
            if (success) success(notification);
        } else {
            runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
                [EntryContext.sharedContext assureSave:^{
                    [notification handle:^ {
                        [weakSelf addHandledNotifications:@[notification]];
                        if (success) success(notification);
                        [operation finish];
                    } failure:^(NSError *error) {
                        if (failure) failure(error);
                        [operation finish];
                    }];
                }];
            });
        }
    } else {
        if (failure) failure([[NSError alloc] initWithMessage:@"Data in remote notification is not valid."]);
    }
}

// MARK: - NotificationSubscriptionDelegate

- (void)notificationSubscription:(NotificationSubscription *)subscription didReceivePresenceEvent:(PNPresenceEventResult * _Nonnull)event {
    if ([event.data.presenceEvent isEqualToString:@"state-change"]) {
        Wrap *wrap = [Wrap entry:event.data.actualChannel];
        User *user = [User entry:event.data.presence.uuid];
        NSDictionary *state = event.data.presence.state;
        if (wrap && user && state) {
            [user fetchIfNeeded:^(id  _Nullable object) {
                [wrap fetchIfNeeded:^(id  _Nullable object) {
                    NSString *chatChannel = state[@"chatChannel"];
                    if ([chatChannel isEqualToString:[User channelName]]) {
                        return;
                    }
                    NSString *viewerURL = state[@"viewerURL"];
                    if (viewerURL != nil) {
                        LiveBroadcast *broadcast = [[LiveBroadcast alloc] init];
                        broadcast.broadcaster = user;
                        broadcast.wrap = wrap;
                        broadcast.title = state[@"title"];
                        broadcast.channel = chatChannel;
                        broadcast.url = viewerURL;
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
            } failure:nil];
        }
    }
}

- (void)notificationSubscription:(NotificationSubscription *)subscription didReceiveMessage:(PNMessageResult * _Nonnull)message {
    [self.enqueuedMessages addObject:message.data];
    [self enqueueSelector:@selector(handleEnqueuedMessages)];
}

- (void)handleEnqueuedMessages {
    NSArray *messages = [self.enqueuedMessages copy];
    [self.enqueuedMessages removeAllObjects];
    NSArray *notifications = [self notificationsFromMessages:messages];
    if (notifications.nonempty) {
        NSMutableIndexSet *playedSoundTypes = [NSMutableIndexSet indexSet];
        
        for (WLNotification *notification in notifications) {
            [notification prepare];
        }
        
        for (WLNotification *notification in notifications) {
            runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
                if (!notification) {
                    [operation finish];
                    return;
                }
                [notification fetch:^{
                    if (![playedSoundTypes containsIndex:notification.type]) [WLSoundPlayer playSoundForNotification:notification];
                    [playedSoundTypes addIndex:notification.type];
                    [operation finish];
                } failure:^(NSError *error) {
                    [operation finish];
                }];
            });
            WLLog(@"PUBNUB - direct message received %@", notification);
        }
        
        runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
            for (WLNotification *notification in notifications) {
                [notification finalize];
            }
            [operation finish];
        });
    }
}

- (void)clear {
    self.userSubscription = nil;
    [NSUserDefaults standardUserDefaults].handledNotifications = nil;
    [NSUserDefaults standardUserDefaults].historyDate = nil;
    [PubNub setSharedInstance:nil];
}

- (BOOL)isAlreadyHandledNotification:(WLNotification*)notification {
    return [[NSUserDefaults standardUserDefaults].handledNotifications containsObject:notification.uid];
}

- (void)handleNotification:(WLNotification*)notification completion:(Block)completion {
    [notification handle:^{
        [WLSoundPlayer playSoundForNotification:notification];
        if (completion) completion();
    } failure:^(NSError *error) {
        if (completion) completion();
    }];
}

- (void)addHandledNotifications:(NSArray*)notifications {
    NSArray *uids = [notifications map:^id(WLNotification* notification) {
        return notification.uid;
    }];
    
    if (uids.nonempty) {
        NSMutableOrderedSet *handledNotifications = [[NSUserDefaults standardUserDefaults].handledNotifications mutableCopy];
        if (handledNotifications.count > 100) {
            [handledNotifications removeObjectsInRange:NSMakeRange(0, MIN(100, uids.count))];
        }
        [handledNotifications unionOrderedSet:[NSOrderedSet orderedSetWithArray:uids]];
        [NSUserDefaults standardUserDefaults].handledNotifications = handledNotifications;
    }
}

- (void)requestHistory {
    __weak typeof(self)weakSelf = self;
    runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
        NSDate *historyDate = [NSUserDefaults standardUserDefaults].historyDate;
        if (historyDate) {
            NSDate *fromDate = historyDate;
            NSDate *toDate = [NSDate now];

            WLLog(@"PUBNUB - requesting history starting from: %@ to: %@", fromDate, toDate);
            
            if  ([WLNetwork sharedNetwork].reachable && weakSelf.userSubscription) {
                
                [weakSelf.userSubscription history:fromDate to:toDate success:^(NSArray *messages) {
                    if (messages.count > 0) {
                        WLLog(@"PUBNUB - received history starting from: %@ to: %@", fromDate, toDate);
                        [weakSelf handleHistoryMessages:messages];
                        [NSUserDefaults standardUserDefaults].historyDate = [[NSDate dateWithTimetoken:[(NSDictionary*)[messages lastObject] numberForKey:@"timetoken"]] dateByAddingTimeInterval:0.001];
                        [weakSelf requestHistory];
                    } else {
                        WLLog(@"PUBNUB - no missed messages in history");
                        [NSUserDefaults standardUserDefaults].historyDate = toDate;
                    }
                    [operation finish];
                } failure:^(NSError *error) {
                    [operation finish];
                }];
            } else {
                [operation finish];
            }
        } else {
            WLLog(@"PUBNUB - history date is empty");
            [NSUserDefaults standardUserDefaults].historyDate = [NSDate now];
            [operation finish];
        }
    });
}

- (void)handleHistoryMessages:(NSArray*)messages {
    NSArray *notifications = [self notificationsFromMessages:messages];
    if (notifications.nonempty) {
        
        NSMutableIndexSet *playedSoundTypes = [NSMutableIndexSet indexSet];
        
        for (WLNotification *notification in notifications) {
            [notification prepare];
        }
        
        for (WLNotification *notification in notifications) {
            runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
                if (!notification) {
                    [operation finish];
                    return;
                }
                [notification fetch:^{
                    if (![playedSoundTypes containsIndex:notification.type]) [WLSoundPlayer playSoundForNotification:notification];
                    [playedSoundTypes addIndex:notification.type];
                    [operation finish];
                } failure:^(NSError *error) {
                    [operation finish];
                }];
            });
            WLLog(@"PUBNUB - history message received %@", notification);
        }
        
        runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
            for (WLNotification *notification in notifications) {
                [notification finalize];
            }
            [operation finish];
        });
    }
}

- (NSArray*)notificationsFromMessages:(NSArray*)messages {
    if (!messages.nonempty) return nil;
    __weak typeof(self)weakSelf = self;
    NSMutableArray *notifications = [[messages map:^id(PNMessageData *message) {
        WLNotification *notification = [WLNotification notificationWithMessage:message];
        if (notification.type != WLNotificationUserUpdate && ![WLAuthorizationRequest authorized]) {
            return nil;
        }
        if (notification.type != WLNotificationCandyAdd && notification.originatedByCurrentUser) {
            return nil;
        }
        return [weakSelf isAlreadyHandledNotification:notification] ? nil : notification;
    }] mutableCopy];
    
    if (!notifications.nonempty) return nil;
    
    [self addHandledNotifications:notifications];
    
    if (notifications.count == 1) {
        return [notifications copy];
    }
    
    NSArray *deleteNotifications = [notifications where:@"event == %d", EventDelete];
    
    for (WLNotification *notification in deleteNotifications) {
        if (![notifications containsObject:notification]) {
            continue;
        }
        NSArray *deleted = [deleteNotifications where:@"descriptor.uid == %@", notification.descriptor.uid];
        NSArray *added = [notifications where:@"event == %d AND descriptor.uid == %@", EventAdd, notification.descriptor.uid];
        if (added.count > deleted.count) {
            added = [added remove:[added lastObject]];
        } else if (added.count < deleted.count) {
            deleted = [deleted remove:[deleted lastObject]];
        }
        [notifications removeObjectsInArray:deleted];
        [notifications removeObjectsInArray:added];
    }
    
    deleteNotifications = [notifications where:@"event == %d", EventDelete];
    
    for (WLNotification *deleteNotification in deleteNotifications) {
        if (![notifications containsObject:deleteNotification]) {
            continue;
        }
        NSString *uid = deleteNotification.descriptor.uid;
        if (uid.nonempty) {
            NSArray *discardedNotifications = [notifications where:@"SELF != %@ AND (descriptor.uid == %@ OR descriptor.container == %@)",deleteNotification, uid, uid];
            [notifications removeObjectsInArray:discardedNotifications];
            if (![deleteNotification.descriptor entryExists]) {
                [notifications removeObject:deleteNotification];
            }
        } else {
            [notifications removeObject:deleteNotification];
        }
    }
    
    [notifications sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
    
    return [notifications copy];
}

#pragma mark - PNObjectEventListener

- (void)client:(PubNub *)client didReceiveMessage:(PNMessageResult *)message {
    WLLog(@"PUBNUB - did receive message");
}

- (void)client:(PubNub *)client didReceivePresenceEvent:(PNPresenceEventResult *)event {
    WLLog(@"PUBNUB - did receive presence event: %@", event.data.presenceEvent);
}

- (void)client:(PubNub *)client didReceiveStatus:(PNSubscribeStatus *)status {
    WLLog(@"PUBNUB - subscribtion status: %@", status.debugDescription);
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
