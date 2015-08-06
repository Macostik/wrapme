//
//  WLPubNubBroadcaster.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLNotificationCenter.h"
#import "WLSoundPlayer.h"
#import "WLEntryNotifier.h"
#import "WLSession.h"
#import "UIDevice+SystemVersion.h"
#import "WLAPIManager.h"
#import "WLOperationQueue.h"
#import "WLEntryNotification.h"
#import "PubNub+SharedInstance.h"
#import "WLNotificationSubscription.h"
#import "WLNotification+PNMessage.h"
#import "NSDate+PNTimetoken.h"

@interface WLNotificationCenter () <PNObjectEventListener, WLEntryNotifyReceiver, WLNotificationSubscriptionDelegate>

@property (strong, nonatomic) WLNotificationSubscription* userSubscription;

@property (strong, nonatomic) NSDate* historyDate;

@property (strong, nonatomic) NSOrderedSet* handledNotifications;

@property (strong, nonatomic) NSMutableArray* enqueuedMessages;

@end

@implementation WLNotificationCenter

@synthesize historyDate = _historyDate;
@synthesize handledNotifications = _handledNotifications;

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

- (NSDate *)historyDate {
    if (!_historyDate) _historyDate = [WLSession object:@"historyDate"];
    return _historyDate;
}

- (void)setHistoryDate:(NSDate *)historyDate {
    if (historyDate) {
        _historyDate = historyDate;
        [WLSession setObject:historyDate key:@"historyDate"];
    }
}

- (void)deviceToken:(WLDataBlock)completion {
    if (self.gettingDeviceTokenBlock) {
        self.gettingDeviceTokenBlock(completion);
    }
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
        __weak typeof(self)weakSelf = self;
        [self deviceToken:^(NSData *data) {
			WLLog(@"PUBNUB", @"apns_device_token", [data description]);
            [weakSelf.userSubscription enableAPNSWithData:data];
        }];
    } else {
        [self.userSubscription subscribe];
    }
    [self requestHistory];
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
        
        for (WLEntryNotification *notification in notifications) {
            [notification prepare];
        }
        
        for (WLEntryNotification *notification in notifications) {
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
            for (WLEntryNotification *notification in notifications) {
                [notification finalize];
            }
            [operation finish];
        });
    }
}

- (void)clear {
    self.userSubscription = nil;
    self.handledNotifications = nil;
    self.historyDate = nil;
    [[[PubNub sharedInstance] currentConfiguration] setUUID:nil];
}

- (BOOL)isAlreadyHandledNotification:(WLNotification*)notification {
    return [self.handledNotifications containsObject:notification.identifier];
}

- (void)handleNotification:(WLEntryNotification*)notification completion:(WLBlock)completion {
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
        NSMutableOrderedSet *handledNotifications = [self.handledNotifications mutableCopy];
        if (handledNotifications.count > 100) {
            [handledNotifications removeObjectsInRange:NSMakeRange(0, MIN(100, identifiers.count))];
        }
        [handledNotifications unionOrderedSet:[NSOrderedSet orderedSetWithArray:identifiers]];
        self.handledNotifications = handledNotifications;
    }
}

- (NSOrderedSet *)handledNotifications {
    if (!_handledNotifications) {
        _handledNotifications = [NSOrderedSet orderedSetWithArray:[WLSession object:@"handledNotifications"]];
    }
    return _handledNotifications;
}

- (void)setHandledNotifications:(NSOrderedSet *)handledNotifications {
    _handledNotifications = handledNotifications;
    [WLSession setObject:[_handledNotifications array] key:@"handledNotifications"];
}

- (void)requestHistory {
    __weak typeof(self)weakSelf = self;
    runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
        NSDate *historyDate = weakSelf.historyDate;
        if (historyDate) {
            NSDate *fromDate = historyDate;
            NSDate *toDate = [NSDate now];

            WLLog(@"PUBNUB", ([NSString stringWithFormat:@"requesting history starting from: %@ to: %@", fromDate, toDate]), nil);
            
            if  ([WLNetwork network].reachable && weakSelf.userSubscription) {
                
                [weakSelf.userSubscription history:fromDate to:toDate success:^(NSArray *messages) {
                    if (messages.count > 0) {
                        WLLog(@"PUBNUB", ([NSString stringWithFormat:@"received history starting from: %@ to: %@", fromDate, toDate]), nil);
                        [weakSelf handleHistoryMessages:messages];
                        weakSelf.historyDate = [[NSDate dateWithTimetoken:[(NSDictionary*)[messages lastObject] numberForKey:@"timetoken"]] dateByAddingTimeInterval:0.001];
                        [weakSelf requestHistory];
                    } else {
                        WLLog(@"PUBNUB", @"no missed messages in history", nil);
                        weakSelf.historyDate = toDate;
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
            weakSelf.historyDate = [NSDate now];
            [operation finish];
        }
    });
}

- (void)handleHistoryMessages:(NSArray*)messages {
    NSArray *notifications = [self notificationsFromMessages:messages];
    if (notifications.nonempty) {
        
        NSMutableIndexSet *playedSoundTypes = [NSMutableIndexSet indexSet];
        
        for (WLEntryNotification *notification in notifications) {
            [notification prepare];
        }
        
        for (WLEntryNotification *notification in notifications) {
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
            for (WLEntryNotification *notification in notifications) {
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
        WLEntryNotification *notification = [WLEntryNotification notificationWithMessage:message];
        return [weakSelf isAlreadyHandledNotification:notification] ? nil : notification;
    }] mutableCopy];
    
    if (!notifications.nonempty) return nil;
    
    [self addHandledNotifications:notifications];
    
    if (notifications.count == 1) {
        return [notifications copy];
    }
    
    NSArray *deleteNotifications = [notifications where:@"event == %d", WLEventDelete];
    
    for (WLEntryNotification *notification in deleteNotifications) {
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
    
    deleteNotifications = [deleteNotifications sortedArrayUsingComparator:^NSComparisonResult(WLEntryNotification* n1, WLEntryNotification* n2) {
        return [[n1.entryClass uploadingOrder] compare:[n2.entryClass uploadingOrder]];
    }];
    
    for (WLEntryNotification *deleteNotification in deleteNotifications) {
        if (![notifications containsObject:deleteNotification]) {
            continue;
        }
        NSString *entryIdentifier = deleteNotification.entryIdentifier;
        if (entryIdentifier.nonempty) {
            NSArray *discardedNotifications = [notifications where:@"SELF != %@ AND (entryIdentifier == %@ OR containingEntryIdentifier == %@)",deleteNotification, entryIdentifier, entryIdentifier];
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

- (void)handleRemoteNotification:(NSDictionary *)data success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (!data)  {
        if (failure) failure(nil);
        return;
    }
    __weak typeof(self)weakSelf = self;
    
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    
    if (state == UIApplicationStateActive) {
        if (failure) failure([NSError errorWithDescription:WLLS(@"remote_notification_when_app_is_active_error")]);
    } else {
        WLNotification* notification = [WLNotification notificationWithData:data];
        WLLog(@"PUBNUB", @"received APNS", data);
        if (notification) {
            if ([notification supportsApplicationState:state]) {
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
                if (failure) failure([NSError errorWithDescription:@"Cannot handle remote notification."]);
            }
        } else {
            if (failure) failure([NSError errorWithDescription:@"Data in remote notification is not valid."]);
        }
    }
}

#pragma mark - PNObjectEventListener

- (void)client:(PubNub *)client didReceiveMessage:(PNMessageResult *)message {
    WLLog(@"PUBNUB", @"did receive message", nil);
}

- (void)client:(PubNub *)client didReceivePresenceEvent:(PNPresenceEventResult *)event {
    WLLog(@"PUBNUB", @"did receive presence event", event.data.presenceEvent);
}

- (void)client:(PubNub *)client didReceiveStatus:(PNSubscribeStatus *)status {
    WLLog(@"PUBNUB", @"did receive status", status.data.subscribedChannel);
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier didAddEntry:(WLEntry *)entry {
    [self subscribe];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return [WLUser currentUser] == entry;
}

@end
