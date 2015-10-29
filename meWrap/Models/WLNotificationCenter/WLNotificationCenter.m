//
//  WLPubNubBroadcaster.m
//  meWrap
//
//  Created by Ravenpod on 5/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationCenter.h"
#import "WLSoundPlayer.h"
#import "WLEntryNotifier.h"
#import "WLSession.h"
#import "WLOperationQueue.h"
#import "PubNub+SharedInstance.h"
#import "WLNotificationSubscription.h"
#import "WLNotification.h"
#import "NSDate+PNTimetoken.h"
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

@interface WLNotificationCenter () <PNObjectEventListener, WLEntryNotifyReceiver, WLNotificationSubscriptionDelegate>

@property (strong, nonatomic) WLNotificationSubscription* userSubscription;

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
    [[WLUser notifier] addReceiver:self];
    [self registerForRemoteNotifications];
}

- (void)setup {
    self.enqueuedMessages = [NSMutableArray array];
    [[PubNub sharedInstance] addListener:self];
}

- (void)subscribe {
    [self subscribeWithUser:[WLUser currentUser]];
}

- (void)subscribeWithUser:(WLUser*)user {
    NSString* uuid = user.identifier;
    if (!uuid.nonempty) {
        return;
    }
    [[PubNub sharedInstance] currentConfiguration].uuid = uuid;
    NSString *channelName = [NSString stringWithFormat:@"cg-%@", uuid];
    if ([self.userSubscription.name isEqualToString:channelName]) {
        [self.userSubscription subscribe];
    } else {
        self.userSubscription = [WLNotificationSubscription subscription:channelName presence:NO group:YES];
        self.userSubscription.delegate = self;
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

- (void)handleRemoteNotification:(NSDictionary *)data success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
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
                [[WLEntryManager manager] assureSave:^{
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
        if (failure) failure([NSError errorWithDescription:@"Data in remote notification is not valid."]);
    }
}

// MARK: - WLNotificationSubscriptionDelegate

- (void)notificationSubscription:(WLNotificationSubscription *)subscription didReceiveMessage:(PNMessageData *)message {
    [self.enqueuedMessages addObject:message];
    [self enqueueSelectorPerforming:@selector(handleEnqueuedMessages)];
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
    WLSession.handledNotifications = nil;
    WLSession.historyDate = nil;
    [[PubNub sharedInstance] currentConfiguration].uuid = nil;
}

- (BOOL)isAlreadyHandledNotification:(WLNotification*)notification {
    return [WLSession.handledNotifications containsObject:notification.identifier];
}

- (void)handleNotification:(WLNotification*)notification completion:(WLBlock)completion {
    [notification handle:^{
        [WLSoundPlayer playSoundForNotification:notification];
        if (completion) completion();
    } failure:^(NSError *error) {
        if (completion) completion();
    }];
}

- (void)addHandledNotifications:(NSArray*)notifications {
    NSArray *identifiers = [notifications map:^id(WLNotification* notification) {
        return notification.identifier;
    }];
    
    if (identifiers.nonempty) {
        NSMutableOrderedSet *handledNotifications = [WLSession.handledNotifications mutableCopy];
        if (handledNotifications.count > 100) {
            [handledNotifications removeObjectsInRange:NSMakeRange(0, MIN(100, identifiers.count))];
        }
        [handledNotifications unionOrderedSet:[NSOrderedSet orderedSetWithArray:identifiers]];
        WLSession.handledNotifications = handledNotifications;
    }
}

- (void)requestHistory {
    __weak typeof(self)weakSelf = self;
    runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
        NSDate *historyDate = WLSession.historyDate;
        if (historyDate) {
            NSDate *fromDate = historyDate;
            NSDate *toDate = [NSDate now];

            WLLog(@"PUBNUB - requesting history starting from: %@ to: %@", fromDate, toDate);
            
            if  ([WLNetwork network].reachable && weakSelf.userSubscription) {
                
                [weakSelf.userSubscription history:fromDate to:toDate success:^(NSArray *messages) {
                    if (messages.count > 0) {
                        WLLog(@"PUBNUB - received history starting from: %@ to: %@", fromDate, toDate);
                        [weakSelf handleHistoryMessages:messages];
                        WLSession.historyDate = [[NSDate dateWithTimetoken:[(NSDictionary*)[messages lastObject] numberForKey:@"timetoken"]] dateByAddingTimeInterval:0.001];
                        [weakSelf requestHistory];
                    } else {
                        WLLog(@"PUBNUB - no missed messages in history");
                        WLSession.historyDate = toDate;
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
            WLSession.historyDate = [NSDate now];
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
    
    NSArray *deleteNotifications = [notifications where:@"event == %d", WLEventDelete];
    
    for (WLNotification *notification in deleteNotifications) {
        if (![notifications containsObject:notification]) {
            continue;
        }
        NSArray *deleted = [deleteNotifications where:@"entryIdentifier == %@", notification.entryIdentifier];
        NSArray *added = [notifications where:@"event == %d AND entryIdentifier == %@", WLEventAdd, notification.entryIdentifier];
        if (added.count > deleted.count) {
            added = [added remove:[added lastObject]];
        } else if (added.count < deleted.count) {
            deleted = [deleted remove:[deleted lastObject]];
        }
        [notifications removeObjectsInArray:deleted];
        [notifications removeObjectsInArray:added];
    }
    
    deleteNotifications = [notifications where:@"event == %d", WLEventDelete];
    
    deleteNotifications = [deleteNotifications sortedArrayUsingComparator:^NSComparisonResult(WLNotification* n1, WLNotification* n2) {
        return [[n1.entryClass uploadingOrder] compare:[n2.entryClass uploadingOrder]];
    }];
    
    for (WLNotification *deleteNotification in deleteNotifications) {
        if (![notifications containsObject:deleteNotification]) {
            continue;
        }
        NSString *entryIdentifier = deleteNotification.entryIdentifier;
        if (entryIdentifier.nonempty) {
            NSArray *discardedNotifications = [notifications where:@"SELF != %@ AND (entryIdentifier == %@ OR containerIdentifier == %@)",deleteNotification, entryIdentifier, entryIdentifier];
            [notifications removeObjectsInArray:discardedNotifications];
            if (![deleteNotification.entryClass entryExists:entryIdentifier]) {
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

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier didAddEntry:(WLEntry *)entry {
    [self subscribeWithUser:(WLUser*)entry];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return [WLUser currentUser] == entry;
}

@end
