//
//  WLPubNubBroadcaster.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLNotificationCenter.h"
#import "UIAlertView+Blocks.h"
#import "WLToast.h"
#import "WLSoundPlayer.h"
#import "WLNotificationChannel.h"
#import "NSPropertyListSerialization+Shorthand.h"
#import "WLEntryNotifier.h"
#import "WLSession.h"
#import "UIDevice+SystemVersion.h"
#import "WLAPIManager.h"
#import "WLOperationQueue.h"
#import "WLEntryNotification.h"

@interface WLNotificationCenter () <PNDelegate, WLEntryNotifyReceiver>

@property (strong, nonatomic) WLNotificationChannel* userChannel;

@property (strong, nonatomic) NSDate* historyDate;

@property (strong, nonatomic) NSOrderedSet* handledNotifications;

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
                if (weakSelf.userChannel.subscribed) {
                    [weakSelf performSelector:@selector(requestHistory) withObject:nil afterDelay:0.5f];
                } else {
                    [weakSelf subscribe];
                }
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

+ (PNConfiguration*)configuration {
    
    NSString* origin, *publishKey, *subscribeKey, *secretKey;
    
    if ([WLAPIManager manager].environment.isProduction) {
        origin = @"pubsub.pubnub.com";
        publishKey = @"pub-c-87bbbc30-fc43-4f6b-b1f4-cedd5f30d5e8";
        subscribeKey = @"sub-c-6562fe64-4270-11e4-aed8-02ee2ddab7fe";
        secretKey = @"sec-c-NGE5NWU0NDAtZWMxYS00ZjQzLWJmMWMtZDU5MTE3NWE0YzE0";
    } else {
        origin = @"pubsub.pubnub.com";
        publishKey = @"pub-c-16ba2a90-9331-4472-b00a-83f01ff32089";
        subscribeKey = @"sub-c-bc5bfa70-d166-11e3-8d06-02ee2ddab7fe";
        secretKey = @"sec-c-MzYyMTY1YzMtYTZkOC00NzU3LTkxMWUtMzgwYjdkNWNkMmFl";
    }
    
	return [PNConfiguration configurationForOrigin:origin publishKey:publishKey subscribeKey:subscribeKey secretKey:secretKey];
}

- (void)configure {
	[self connect];
    [PNLogger loggerEnabled:NO];
    [[WLUser notifier] addReceiver:self];
}

- (void)setup {
	[PubNub setupWithConfiguration:[WLNotificationCenter configuration] andDelegate:self];
}

- (void)subscribe {
	NSString* userUID = [WLUser currentUser].identifier;
    NSString* deviceUID = [WLAuthorization currentAuthorization].deviceUID;
	if (!userUID.nonempty || !deviceUID.nonempty) {
		return;
	}
    if (![[PubNub clientIdentifier] isEqualToString:userUID]) {
        [PubNub setClientIdentifier:userUID];
    }
    NSString *channelName = [NSString stringWithFormat:@"%@-%@", userUID, deviceUID];
    if (![self.userChannel.channel.name isEqualToString:channelName]) {
        self.userChannel = [WLNotificationChannel channelWithName:channelName];
        __weak typeof(self)weakSelf = self;
        [self.userChannel enableAPNS];
        [self.userChannel observeMessages:^(PNMessage *message) {
            WLEntryNotification *notification = [WLEntryNotification notificationWithMessage:message];
            
            if (notification && ![weakSelf isAlreadyHandledNotification:notification]) {
                runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
                    [weakSelf handleNotification:notification completion:^{
                        [operation finish];
                    }];
                });
                [weakSelf addHandledNotifications:@[notification]];
            }
            
            NSString *logMessage = [NSString stringWithFormat:@"direct message received %@", notification];
            WLLog(@"PUBNUB", logMessage, notification.entryData);
        }];
    } else if (!self.userChannel.subscribed) {
        [self.userChannel subscribe];
    }
    [self requestHistory];
}

- (void)clear {
    self.userChannel = nil;
    self.handledNotifications = nil;
    self.historyDate = nil;
    [PubNub setClientIdentifier:nil];
}

- (BOOL)isAlreadyHandledNotification:(WLNotification*)notification {
    return [self.handledNotifications containsObject:notification.identifier];
}

- (void)handleNotification:(WLEntryNotification*)notification completion:(WLBlock)completion {
    [notification fetch:^{
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
            NSString *logMessage = [NSString stringWithFormat:@"requesting history starting from: %@ to: %@", fromDate, toDate];
            WLLog(@"PUBNUB", logMessage, nil);
            if  ([WLNetwork network].reachable) {
                [PubNub requestHistoryForChannel:weakSelf.userChannel.channel from:[PNDate dateWithDate:fromDate] to:[PNDate dateWithDate:toDate] includingTimeToken:YES withCompletionBlock:^(NSArray *messages, id channel, PNDate* from, PNDate* to, id error) {
                    if (!error) {
                        [weakSelf handleHistoryMessages:messages from:[from date] to:toDate];
                    } else {
                        WLLog(@"PUBNUB", @"requesting history error", error);
                    }
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

- (void)handleHistoryMessages:(NSArray*)messages from:(NSDate*)from to:(NSDate*)to {
    NSString *logMessage = [NSString stringWithFormat:@"received history starting from: %@ to: %@", from, to];
    WLLog(@"PUBNUB", logMessage, nil);
    NSArray *notifications = [self notificationsFromMessages:messages];
    if (notifications.nonempty) {
        
        NSMutableIndexSet *playedSoundTypes = [NSMutableIndexSet indexSet];
        
        for (WLEntryNotification *notification in notifications) {
            runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
                [notification fetch:^{
                    if (![playedSoundTypes containsIndex:notification.type]) [WLSoundPlayer playSoundForNotification:notification];
                    [playedSoundTypes addIndex:notification.type];
                    [operation finish];
                } failure:^(NSError *error) {
                    [operation finish];
                }];
            });
            NSString *logMessage = [NSString stringWithFormat:@"history message received %@", notification];
            WLLog(@"PUBNUB", logMessage, notification.entryData);
        }
        WLNotification *notification = [notifications lastObject];
        NSDate *notificationDate = notification.date;
        self.historyDate = notificationDate ? [notificationDate dateByAddingTimeInterval:NSINTEGER_DEFINED] : to;
    } else {
        self.historyDate = to;
        WLLog(@"PUBNUB", @"no missed messages in history", nil);
    }
}

- (NSArray*)notificationsFromMessages:(NSArray*)messages {
    if (!messages.nonempty) return nil;
    __weak typeof(self)weakSelf = self;
    NSMutableArray *notifications = [[messages map:^id(PNMessage *message) {
        WLEntryNotification *notification = [WLEntryNotification notificationWithMessage:message];
        return [weakSelf isAlreadyHandledNotification:notification] ? nil : notification;
    }] mutableCopy];
    
    if (!notifications.nonempty) return nil;
    
    [self addHandledNotifications:notifications];
    
    NSArray *deleteNotifications = [notifications objectsWhere:@"event == %d", WLEventDelete];
    
    for (WLEntryNotification *notification in deleteNotifications) {
        if (![notifications containsObject:notification]) {
            continue;
        }
        NSArray *deleted = [deleteNotifications objectsWhere:@"entryIdentifier == %@", notification.entryIdentifier];
        NSArray *added = [notifications objectsWhere:@"event == %d AND entryIdentifier == %@", WLEventAdd, notification.entryIdentifier];
        if (added.count > deleted.count) {
            added = [added arrayByRemovingObject:[added lastObject]];
        } else if (added.count < deleted.count) {
            deleted = [deleted arrayByRemovingObject:[deleted lastObject]];
        }
        [notifications removeObjectsInArray:deleted];
        [notifications removeObjectsInArray:added];
    }
    
    deleteNotifications = [notifications objectsWhere:@"event == %d", WLEventDelete];
    
    deleteNotifications = [deleteNotifications sortedArrayUsingComparator:^NSComparisonResult(WLEntryNotification* n1, WLEntryNotification* n2) {
        return [[n1.entryClass uploadingOrder] compare:[n2.entryClass uploadingOrder]];
    }];
    
    for (WLEntryNotification *deleteNotification in deleteNotifications) {
        if (![notifications containsObject:deleteNotification]) {
            continue;
        }
        NSString *entryIdentifier = deleteNotification.entryIdentifier;
        if (entryIdentifier.nonempty) {
            NSArray *discardedNotifications = [notifications objectsWhere:@"SELF != %@ AND (entryIdentifier == %@ OR containingEntryIdentifier == %@)",deleteNotification, entryIdentifier, entryIdentifier];
            [notifications removeObjectsInArray:discardedNotifications];
            if (![[WLEntryManager manager] entryExists:deleteNotification.entryClass identifier:entryIdentifier]) {
                [notifications removeObject:deleteNotification];
            }
        } else {
            [notifications removeObject:deleteNotification];
        }
    }
    
    [notifications sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
    
    return [notifications copy];
}

- (void)connect {
	[PubNub connect];
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
                    [notification fetch:^ {
                        [weakSelf addHandledNotifications:@[notification]];
                        if (success) success(notification);
                    } failure:failure];
                }
            } else {
                if (failure) failure([NSError errorWithDescription:@"Cannot handle remote notification."]);
            }
        } else {
            if (failure) failure([NSError errorWithDescription:@"Data in remote notification is not valid."]);
        }
    }
}

#pragma mark - PNDelegate

- (void)pubnubClient:(PubNub *)client didReceiveMessageHistory:(NSArray *)messages forChannel:(PNChannel *)channel startingFrom:(PNDate *)startDate to:(PNDate *)endDate {
    WLLog(@"PUBNUB",@"messages history with count", @([messages count]));
}

- (void)pubnubClient:(PubNub *)client didConnectToOrigin:(NSString *)origin {
    WLLog(@"PUBNUB",@"connected", origin);
    if (self.userChannel.subscribed) {
        [self requestHistory];
    }
}

- (void)pubnubClient:(PubNub *)client connectionDidFailWithError:(PNError *)error {
    WLLog(@"PUBNUB",@"connection failed", error);
}

- (void)pubnubClient:(PubNub *)client didSubscribeOnChannels:(NSArray *)channels {
    WLLog(@"PUBNUB",@"subscribed", [channels valueForKey:@"name"]);
}

- (void)pubnubClient:(PubNub *)client didUnsubscribeOnChannels:(NSArray *)channels {
    WLLog(@"PUBNUB",@"unsubscribed", [channels valueForKey:@"name"]);
}

- (void)pubnubClient:(PubNub *)client didDisconnectFromOrigin:(NSString *)origin withError:(PNError *)error {
    WLLog(@"PUBNUB", @"disconnected", error);
}

- (void)pubnubClient:(PubNub *)client didEnablePushNotificationsOnChannels:(NSArray *)channels {
    WLLog(@"PUBNUB", @"enabled APNS", [channels valueForKey:@"name"]);
}

- (void)pubnubClientDidRemovePushNotifications:(PubNub *)client {
    WLLog(@"PUBNUB", @"removed APNS", nil);
}

- (void)pubnubClient:(PubNub *)client didReceivePresenceEvent:(PNPresenceEvent *)event {
    WLLog(@"PUBNUB", @"presence event", @(event.type));
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier entryAdded:(WLEntry *)entry {
    [self subscribe];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return [WLUser currentUser] == entry;
}

@end
