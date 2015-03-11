//
//  WLPubNubBroadcaster.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/13/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLNotificationCenter.h"
#import "NSArray+Additions.h"
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
#import "WLRemoteObjectHandler.h"
#import "WLImageFetcher.h"
#import "WLOperationQueue.h"
#import "WLEntryNotifier.h"
#import "WLNetwork.h"

@interface WLNotificationCenter () <PNDelegate, WLNetworkReceiver>

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
        __weak typeof(self)weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            if (weakSelf.userChannel.subscribed) {
                [weakSelf performSelector:@selector(requestHistory) withObject:nil afterDelay:0.5f];
            } else {
                [weakSelf subscribe];
            }
        }];
        
        [[WLNetwork network] addReceiver:self];
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
    
    if ([WLAPIManager instance].environment.isProduction) {
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
    [super configure];
}

- (void)setup {
    [super setup];
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
            WLNotification *notification = [WLNotification notificationWithMessage:message];
            
            if (notification) {
                [WLEntryNotifier beginBatchUpdates];
                runUnaryQueuedOperation(@"wl_fetching_data_queue", ^(WLOperation *operation) {
                    [weakSelf handleNotification:notification completion:^{
                        [operation finish:^{
                            [WLEntryNotifier commitBatchUpdates];
                        }];
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

- (BOOL)notificationHandled:(WLNotification*)notification {
    return [self.handledNotifications containsObject:notification.identifier];
}

- (void)handleNotification:(WLNotification*)notification completion:(WLBlock)completion {
    BOOL insertedEntry = notification.targetEntry.inserted;
    [notification fetch:^{
        if (notification.playSound && insertedEntry) [WLSoundPlayer playSoundForNotification:notification];
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
    runUnaryQueuedOperation(@"wl_fetching_data_queue", ^(WLOperation *operation) {
        NSDate *historyDate = weakSelf.historyDate;
        if (historyDate) {
            NSDate *fromDate = historyDate;
            NSDate *toDate = [NSDate now];
            NSString *logMessage = [NSString stringWithFormat:@"requesting history starting from: %@ to: %@", fromDate, toDate];
            WLLog(@"PUBNUB", logMessage, nil);
            [PubNub requestHistoryForChannel:weakSelf.userChannel.channel from:[PNDate dateWithDate:fromDate] to:[PNDate dateWithDate:toDate] includingTimeToken:YES withCompletionBlock:^(NSArray *messages, id channel, PNDate* from, PNDate* to, id error) {
                if (!error) {
                    [weakSelf handleHistoryMessages:messages from:[from date] to:toDate];
                } else {
                    WLLog(@"PUBNUB", @"requesting history error", error);
                }
                [operation finish];
            }];
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
        [WLEntryNotifier beginBatchUpdates];
        for (WLNotification *notification in notifications) {
            runUnaryQueuedOperation(@"wl_fetching_data_queue", ^(WLOperation *_operation) {
                [notification fetch:^{
                    [_operation finish:^{
                        [WLEntryNotifier commitBatchUpdates];
                    }];
                } failure:^(NSError *error) {
                    [_operation finish:^{
                        [WLEntryNotifier commitBatchUpdates];
                    }];
                }];
            });
            NSString *logMessage = [NSString stringWithFormat:@"history message received %@", notification];
            WLLog(@"PUBNUB", logMessage, notification.entryData);
        }
        [self addHandledNotifications:notifications];
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
    NSMutableArray *notifications = [[messages map:^id(PNMessage *message) {
        return [WLNotification notificationWithMessage:message];
    }] mutableCopy];
    
    // remove already handled notifications
    __weak typeof(self)weakSelf = self;
    [notifications removeObjectsWhileEnumerating:^BOOL(WLNotification* notification) {
        return [weakSelf notificationHandled:notification];
    }];
    
    if (!notifications.nonempty) return nil;
    
    NSArray *deleteNotifications = [notifications objectsWhere:@"event == %d", WLEventDelete];
    
    for (WLNotification *notification in deleteNotifications) {
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
    
    deleteNotifications = [deleteNotifications sortedArrayUsingComparator:^NSComparisonResult(WLNotification* n1, WLNotification* n2) {
        return [[n1.entryClass uploadingOrder] compare:[n2.entryClass uploadingOrder]];
    }];
    
    for (WLNotification *deleteNotification in deleteNotifications) {
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

- (void)handleRemoteNotification:(NSDictionary *)data success:(WLBlock)success failure:(WLFailureBlock)failure {
    if (!data)  {
        if (failure) failure(nil);
        return;
    }
    switch ([UIApplication sharedApplication].applicationState) {
        case UIApplicationStateActive:
            if (failure) failure([NSError errorWithDescription:WLLS(@"Cannot handle remote notification when app is active.")]);
            break;
        case UIApplicationStateInactive: {
            WLNotification* notification = [WLNotification notificationWithData:data];
            if (notification) {
                [notification fetch:^{
                    [notification handleRemoteObject];
                    if (success) success();
                } failure:failure];
            } else if (failure)  {
                failure([NSError errorWithDescription:@"Data in remote notification is not valid (inactive)."]);
            }
        } break;
        case UIApplicationStateBackground: {
            WLNotification* notification = [WLNotification notificationWithData:data];
            if (notification) {
                [notification fetch:success failure:failure];
            } else if (failure)  {
                failure([NSError errorWithDescription:WLLS(@"Data in remote notification is not valid (background).")]);
            }
        } break;
        default:
            break;
    }
}

#pragma mark - PNDelegate

- (void)pubnubClient:(PubNub *)client didReceiveMessageHistory:(NSArray *)messages forChannel:(PNChannel *)channel startingFrom:(PNDate *)startDate to:(PNDate *)endDate {
    WLLog(@"PUBNUB",@"messages history with count", @([messages count]));
}

- (void)pubnubClient:(PubNub *)client didConnectToOrigin:(NSString *)origin {
    WLLog(@"PUBNUB",@"connected", origin);
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

// MARK: - WLNetworkReceiver

- (void)networkDidChangeReachability:(WLNetwork *)network {
    if (network.reachable) {
        if (self.userChannel.subscribed) {
            [self requestHistory];
        }
    }
}

@end
