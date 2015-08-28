//
//  WLPubNubBroadcaster.m
//  moji
//
//  Created by Ravenpod on 5/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationCenter.h"
#import "WLSoundPlayer.h"
#import "WLEntryNotifier.h"
#import "WLSession.h"
#import "UIDevice+SystemVersion.h"
#import "WLOperationQueue.h"
#import "PubNub+SharedInstance.h"
#import "WLNotificationSubscription.h"
#import "WLNotification.h"
#import "NSDate+PNTimetoken.h"
#import <PushKit/PushKit.h>
#import "WLEntry+LocalNotifications.h"

@interface WLNotificationCenter () <PNObjectEventListener, WLEntryNotifyReceiver, WLNotificationSubscriptionDelegate, PKPushRegistryDelegate>

@property (strong, nonatomic) WLNotificationSubscription* userSubscription;

@property (strong, nonatomic) NSMutableArray* enqueuedMessages;

@property (strong, nonatomic) PKPushRegistry *pushRegistry;

@property (strong, nonatomic) NSData *pushToken;

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
}

- (void)setup {
    self.enqueuedMessages = [NSMutableArray array];
    [[PubNub sharedInstance] addListener:self];
}

- (void)subscribe {
	NSString* userUID = [WLUser currentUser].identifier;
    NSString* deviceUID = [WLAuthorization currentAuthorization].deviceUID;
	if (!userUID.nonempty || !deviceUID.nonempty) {
		return;
	}
    if (![[[[PubNub sharedInstance] currentConfiguration] uuid] isEqualToString:userUID]) {
        [[[PubNub sharedInstance] currentConfiguration] setUUID:userUID];
    }
    NSString *channelName = [NSString stringWithFormat:@"%@-%@", userUID, deviceUID];
    if (![self.userSubscription.name isEqualToString:channelName]) {
        self.userSubscription = [WLNotificationSubscription subscription:channelName];
        self.userSubscription.delegate = self;
        [self registerForVoIPPushes];
    } else {
        [self.userSubscription subscribe];
    }
    [self requestHistory];
}

- (void)registerForVoIPPushes {
    self.pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    self.pushRegistry.delegate = self;
    self.pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

// MARK: - PKPushRegistryDelegate

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    self.pushToken = credentials.token;
    WLLog(@"PUBNUB", @"apns_device_token", self.pushToken);
    [self.userSubscription enableAPNSWithData:self.pushToken];
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(NSString *)type {
    
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if (state == UIApplicationStateActive) {
        return;
    }
    NSDictionary *userInfo = payload.dictionaryPayload;
    [self handleRemoteNotification:userInfo success:^(WLNotification *notification) {
        if (notification.presentable) {
            WLEntry *entry = notification.entry;
            if ([entry locallyNotifiableNotification:notification] && [entry notifiableForNotification:notification]) {
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                    UILocalNotification *localNotification = [entry localNotificationForNotification:notification];
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }
            }
        }
    } failure:^(NSError *error) {
    }];
}

- (void)handleRemoteNotification:(NSDictionary *)data success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (!data)  {
        if (failure) failure(nil);
        return;
    }
    __weak typeof(self)weakSelf = self;
    WLNotification* notification = [WLNotification notificationWithData:data];
    WLLog(@"PUBNUB", @"received APNS", data);
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
            WLLog(@"PUBNUB", ([NSString stringWithFormat:@"direct message received %@", notification]), notification.entryData);
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
    [[[PubNub sharedInstance] currentConfiguration] setUUID:nil];
    [[PubNub sharedInstance] removeAllPushNotificationsFromDeviceWithPushToken:self.pushToken andCompletion:nil];
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
    return;
    __weak typeof(self)weakSelf = self;
    runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
        NSDate *historyDate = WLSession.historyDate;
        if (historyDate) {
            NSDate *fromDate = historyDate;
            NSDate *toDate = [NSDate now];

            WLLog(@"PUBNUB", ([NSString stringWithFormat:@"requesting history starting from: %@ to: %@", fromDate, toDate]), nil);
            
            if  ([WLNetwork network].reachable && weakSelf.userSubscription) {
                
                [weakSelf.userSubscription history:fromDate to:toDate success:^(NSArray *messages) {
                    if (messages.count > 0) {
                        WLLog(@"PUBNUB", ([NSString stringWithFormat:@"received history starting from: %@ to: %@", fromDate, toDate]), nil);
                        [weakSelf handleHistoryMessages:messages];
                        WLSession.historyDate = [[NSDate dateWithTimetoken:[(NSDictionary*)[messages lastObject] numberForKey:@"timetoken"]] dateByAddingTimeInterval:0.001];
                        [weakSelf requestHistory];
                    } else {
                        WLLog(@"PUBNUB", @"no missed messages in history", nil);
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
            WLLog(@"PUBNUB", @"history date is empty", nil);
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
            WLLog(@"PUBNUB", ([NSString stringWithFormat:@"history message received %@", notification]), notification.entryData);
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
    WLLog(@"PUBNUB", @"did receive message", nil);
}

- (void)client:(PubNub *)client didReceivePresenceEvent:(PNPresenceEventResult *)event {
    WLLog(@"PUBNUB", @"did receive presence event", event.data.presenceEvent);
}

- (void)client:(PubNub *)client didReceiveStatus:(PNSubscribeStatus *)status {
    WLLog(@"PUBNUB", @"did receive status", status.subscribedChannels);
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier didAddEntry:(WLEntry *)entry {
    [self subscribe];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return [WLUser currentUser] == entry;
}

@end
