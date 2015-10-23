//
//  WLNotificationChannel.m
//  meWrap
//
//  Created by Ravenpod on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationSubscription.h"
#import "WLUser.h"
#import "NSDate+PNTimetoken.h"

@interface WLNotificationSubscription () <PNObjectEventListener>

@property (nonatomic) BOOL presence;

@property (nonatomic) BOOL group;

@end

@implementation WLNotificationSubscription

+ (instancetype)subscription:(NSString *)name {
    return [self subscription:name presence:NO];
}

+ (instancetype)subscription:(NSString *)name presence:(BOOL)presence {
    return [self subscription:name presence:presence group:NO];
}

+ (instancetype)subscription:(NSString *)name presence:(BOOL)presence group:(BOOL)group {
    WLNotificationSubscription *subscription = [[self alloc] init];
    subscription.presence = presence;
    subscription.group = group;
    subscription.name = name;
    [subscription subscribe];
    return subscription;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[PubNub sharedInstance] addListener:self];
    }
    return self;
}

- (void)dealloc {
    [self unsubscribe];
}

- (BOOL)subscribed {
    return [[PubNub sharedInstance] isSubscribedOn:self.name];
}

- (void)subscribe {
    if (self.subscribed) {
        return;
    }
    if (self.group) {
        WLLog(@"PUBNUB - is about to subscribe on channel group %@", self.name);
        [[PubNub sharedInstance] subscribeToChannelGroups:@[self.name] withPresence:self.presence];
    } else {
        WLLog(@"PUBNUB - is about to subscribe on channel %@", self.name);
        [[PubNub sharedInstance] subscribeToChannels:@[self.name] withPresence:self.presence];
    }
}

- (void)unsubscribe {
    if (!self.subscribed) {
        return;
    }
    if (self.group) {
        [[PubNub sharedInstance] unsubscribeFromChannelGroups:@[self.name] withPresence:self.presence];
    } else {
        [[PubNub sharedInstance] unsubscribeFromChannels:@[self.name] withPresence:self.presence];
    }
}

- (void)send:(NSDictionary *)message {
    [[PubNub sharedInstance] publish:message toChannel:self.name withCompletion:nil];
}

- (void)changeState:(NSDictionary*)state {
    [[PubNub sharedInstance] setState:state forUUID:[WLUser currentUser].identifier onChannel:self.name withCompletion:nil];
}

- (void)hereNow:(WLArrayBlock)completion {
    [[PubNub sharedInstance] hereNowForChannel:self.name withVerbosity:PNHereNowState completion:^(PNPresenceChannelHereNowResult *result, PNErrorStatus *status) {
        if (!status.isError && completion) {
            completion([result.data uuids]);
        }
    }];
}

- (void)history:(NSDate *)from to:(NSDate *)to success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    NSNumber *startDate = [from timetoken];
    NSNumber *endDate = [to timetoken];
    if (self.group) {
        [[PubNub sharedInstance] channelsForGroup:self.name withCompletion:^(PNChannelGroupChannelsResult *result, PNErrorStatus *status) {
            if (status.isError) {
                if (failure) failure(nil);
            } else {
                NSArray *channels = result.data.channels;
                if (channels.nonempty) {
                    NSMutableSet *fetchedChannels = [NSMutableSet set];
                    NSMutableArray *messages = [NSMutableArray array];
                    for (NSString *channel in channels) {
                        [[PubNub sharedInstance] historyForChannel:channel start:startDate end:endDate includeTimeToken:YES withCompletion:^(PNHistoryResult *result, PNErrorStatus *status) {
                            [fetchedChannels addObject:channel];
                            NSArray *_messages = result.data.messages;
                            if (!status.isError && _messages.nonempty) {
                                [messages addObjectsFromArray:_messages];
                            }
                            if (fetchedChannels.count == channels.count) {
                                [messages sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timetoken" ascending:YES]]];
                                if (success) success([messages copy]);
                            }
                        }];
                    }
                } else {
                    if (success) success(nil);
                }
            }
        }];
    } else {
        [[PubNub sharedInstance] historyForChannel:self.name start:startDate end:endDate includeTimeToken:YES withCompletion:^(PNHistoryResult *result, PNErrorStatus *status) {
            if (!status.isError) {
                if (success) success(result.data.messages);
            } else {
                if (failure) failure(nil);
            }
        }];
    }
}

// MARK: - PNObjectEventListener

- (void)didReceiveMessage:(PNMessageData*)message {
    if ([self.delegate respondsToSelector:@selector(notificationSubscription:didReceiveMessage:)]) {
        [self.delegate notificationSubscription:self didReceiveMessage:message];
    }
}

- (void)didReceivePresenceEvent:(PNPresenceEventData*)event {
    if ([self.delegate respondsToSelector:@selector(notificationSubscription:didReceivePresenceEvent:)]) {
        [self.delegate notificationSubscription:self didReceivePresenceEvent:event];
    }
}

- (void)client:(PubNub *)client didReceiveMessage:(PNMessageResult *)message {
    PNMessageData *data = message.data;
    if ([data.actualChannel isEqualToString:self.name] || [data.subscribedChannel isEqualToString:self.name]) {
        [self didReceiveMessage:data];
    }
}

- (void)client:(PubNub *)client didReceivePresenceEvent:(PNPresenceEventResult *)event {
    PNPresenceEventData *data = event.data;
    if ([data.actualChannel isEqualToString:self.name] || [data.subscribedChannel isEqualToString:self.name]) {
        [self didReceivePresenceEvent:data];
    }
}

@end
