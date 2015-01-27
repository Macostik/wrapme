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
#import "AsynchronousOperation.h"

@interface WLNotificationCenter () <PNDelegate>

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

- (instancetype)init {
    self = [super init];
    if (self) {
        __weak typeof(self)weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            if (weakSelf.userChannel.subscribed) {
                [weakSelf performSelector:@selector(requestHistory:) withObject:weakSelf.historyDate afterDelay:0.5f];
            }
        }];
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
        self.userChannel = [WLNotificationChannel channelWithName:[NSString stringWithFormat:@"%@-%@", userUID, deviceUID]];
        [self requestHistory:self.historyDate];
        __weak typeof(self)weakSelf = self;
        [self.userChannel enableAPNS];
        [self.userChannel observeMessages:^(PNMessage *message) {
            WLNotification *notification = [WLNotification notificationWithMessage:message];
            [weakSelf handleNotification:notification allowSound:YES];
            self.historyDate = [notification.date dateByAddingTimeInterval:NSINTEGER_DEFINED];
        }];
    }
}

- (void)handleNotification:(WLNotification*)notification allowSound:(BOOL)allowSound {
    NSString *logMessage = [NSString stringWithFormat:@"message received %lu : %@", notification.type, notification.entryIdentifier];
    WLLog(@"PUBNUB", logMessage, notification.entryData);
    BOOL insertedEntry = notification.targetEntry.inserted;
    [notification fetch:^{
        if (allowSound && notification.playSound && insertedEntry) [WLSoundPlayer playSoundForNotification:notification];
    } failure:nil];
}

- (void)requestHistory:(NSDate*)historyDate {
    __weak typeof(self)weakSelf = self;
    [[NSOperationQueue queueWithIdentifier:@"pn_history" count:1] addAsynchronousOperationWithBlock:^(AsynchronousOperation *operation) {
        if (historyDate) {
            NSDate *fromDate = historyDate;
            NSDate *toDate = [NSDate now];
            NSString *logMessage = [NSString stringWithFormat:@"requesting history starting from: %@ to: %@", fromDate, toDate];
            WLLog(@"PUBNUB", logMessage, nil);
            [PubNub requestHistoryForChannel:weakSelf.userChannel.channel from:[PNDate dateWithDate:fromDate] to:[PNDate dateWithDate:toDate] includingTimeToken:YES withCompletionBlock:^(NSArray *messages, id channel, id from, id to, id error) {
                if (!error) {
                    NSArray *notifications = [weakSelf notificationsFromMessages:messages];
                    if (notifications.nonempty) {
                        for (WLNotification *notification in notifications) {
                            [weakSelf handleNotification:notification allowSound:NO];
                        }
                    } else {
                        WLLog(@"PUBNUB", @"no missed messages in history", nil);
                    }
                    weakSelf.historyDate = toDate;
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
    }];
}

- (NSArray*)notificationsFromMessages:(NSArray*)messages {
    if (!messages.nonempty) return nil;
    NSMutableArray *notifications = [[messages map:^id(PNMessage *message) {
        return [WLNotification notificationWithMessage:message];
    }] mutableCopy];
    
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

- (NSArray*)notificationsFromMessages:(NSArray*)messages {
    if (!messages.nonempty) return nil;
    NSMutableArray *notifications = [[messages map:^id(PNMessage *message) {
        return [WLNotification notificationWithMessage:message];
    }] mutableCopy];
    
    NSArray *deleteNotifications = [notifications objectsWhere:@"event == %d", WLEventDelete];
    
    deleteNotifications = [deleteNotifications sortedArrayUsingComparator:^NSComparisonResult(WLNotification* n1, WLNotification* n2) {
        return [[[n1.targetEntry class] uploadingOrder] compare:[[n2.targetEntry class] uploadingOrder]];
    }];
    
    for (WLNotification *deleteNotification in deleteNotifications) {
        WLEntry *targetEntry = deleteNotification.targetEntry;
        if (targetEntry.valid) {
            NSArray *discardedNotifications = [notifications objectsWhere:@"SELF != %@ AND (targetEntry == %@ OR targetEntry.containingEntry == %@)",deleteNotification,targetEntry, targetEntry];
            [notifications removeObjectsInArray:discardedNotifications];
            if (targetEntry.inserted) {
                [[WLEntryManager manager] deleteEntry:targetEntry];
                [notifications removeObject:deleteNotification];
            }
        } else {
            [notifications removeObject:deleteNotification];
        }
    }
    
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
                [notification fetch:^{
                    if (notification.type == WLNotificationCandyAdd) {
                        WLCandy* candy = (id)notification.targetEntry;
                        [candy.picture fetch:success];
                    } else {
                        if (success) success();
                    }
                } failure:failure];
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

@end
