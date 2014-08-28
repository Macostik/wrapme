//
//  WLNotificationChannel.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationChannel.h"
#import <PubNub/PubNub.h>
#import "WLNotificationCenter.h"
#import "WLNotification.h"
#import "WLUser+Extended.h"
#import "NSString+Additions.h"

@interface WLNotificationChannel ()

@property (strong, nonatomic) PNChannel* channel;

@end

@implementation WLNotificationChannel

+ (instancetype)channel:(NSString *)name {
    return [self channel:name subscribe:NO];
}

+ (instancetype)channel:(NSString *)name subscribe:(BOOL)subscribe {
    WLNotificationChannel* channel = [[WLNotificationChannel alloc] init];
    [channel setName:name subscribe:subscribe];
    return channel;
}

- (void)dealloc {
    [[PNObservationCenter defaultCenter] removeMessageReceiveObserver:self];
    [[PNObservationCenter defaultCenter] removePresenceEventObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self observeMessages];
        [self observePresense];
    }
    return self;
}

- (void)setName:(NSString *)name {
    [self setName:name subscribe:NO];
}

- (void)setName:(NSString *)name subscribe:(BOOL)subscribe {
    if (self.channel) {
        if ([self.name isEqualToString:name]) {
            if (subscribe) [self subscribe];
        } else {
            [self unsubscribe];
            self.channel = [PNChannel channelWithName:name];
            if (subscribe) [self subscribe];
        }
    } else {
        self.channel = [PNChannel channelWithName:name];
        if (subscribe) [self subscribe];
    }
}

- (NSString *)name {
    return self.channel.name;
}

- (BOOL)subscribed {
    return self.channel && [PubNub isSubscribedOnChannel:self.channel];
}

- (void)subscribe {
    [self subscribe:nil failure:nil];
}

- (void)subscribe:(WLBlock)success failure:(WLFailureBlock)failure {
    if (self.subscribed) {
        if (success) success();
        return;
    }
    __weak typeof(self)weakSelf = self;
    [PubNub subscribeOnChannel:self.channel withCompletionHandlingBlock:^(PNSubscriptionProcessState state, NSArray *channels, PNError *error) {
        if (error) {
            if (failure) failure(error);
        } else {
            if (weakSelf.supportAPNS) [weakSelf enableAPNS];
            if (weakSelf.supportPresense) [weakSelf enablePresense];
            if (success) success();
        }
    }];
}

- (void)unsubscribe {
    [self unsubscribe:nil failure:nil];
}

- (void)unsubscribe:(WLBlock)success failure:(WLFailureBlock)failure {
    if (!self.subscribed) {
        if (success) success();
        return;
    }
    [PubNub unsubscribeFromChannel:self.channel withCompletionHandlingBlock:^(NSArray *channels, PNError *error) {
        if (error) {
            if (failure) failure(error);
        } else if (success) {
            success();
        }
    }];
}

- (void)enableAPNS {
    __weak typeof(self)weakSelf = self;
    [WLNotificationCenter deviceToken:^(NSData *data) {
        if (![[PubNub sharedInstance] isConnected] || !data || !weakSelf.channel.name.nonempty) {
            return;
        }
        
        [PubNub requestParticipantsListWithCompletionBlock:^(NSArray *participants, PNChannel *channel, PNError *error) {
            if (!error) {
                for (PNClient *client in participants) {
                    if (![client.channel.name isEqualToString:weakSelf.channel.name]) {
                        [PubNub disablePushNotificationsOnChannel:client.channel withDevicePushToken:data];
                    }
                }
            }
        }];
        
        [PubNub removeAllPushNotificationsForDevicePushToken:data withCompletionHandlingBlock:^(PNError *error) {
            [PubNub enablePushNotificationsOnChannel:weakSelf.channel withDevicePushToken:data];
        }];
    }];
}

- (void)observeMessages {
    __weak typeof(self)weakSelf = self;
    [[PNObservationCenter defaultCenter] addMessageReceiveObserver:self withBlock:^(PNMessage *message) {
        if (message.channel == weakSelf.channel && weakSelf.receive) {
            weakSelf.receive([WLNotification notificationWithMessage:message]);
        }
    }];
}

- (void)observePresense {
    __weak typeof(self)weakSelf = self;
    [[PNObservationCenter defaultCenter] addPresenceEventObserver:self withBlock:^(PNPresenceEvent *event) {
        if (event.channel == weakSelf.channel && weakSelf.presenseObserver) {
            weakSelf.presenseObserver(event);
        }
    }];
}

- (void)enablePresense {
    [PubNub enablePresenceObservationForChannel:self.channel];
}

- (void)send:(NSDictionary *)message {
    if (self.subscribed) {
        [PubNub sendMessage:message toChannel:self.channel];
    }
}

- (void)changeState:(NSDictionary*)state {
    [PubNub updateClientState:[WLUser currentUser].identifier state:state forChannel:self.channel];
}

- (void)participants:(WLArrayBlock)completion {
    if (self.subscribed) {
        [PubNub requestParticipantsListForChannel:self.channel clientIdentifiersRequired:YES clientState:YES withCompletionBlock:^(NSArray *participants, PNChannel *channel, PNError *error) {
            if (!error && completion) {
                completion(participants);
            }
        }];
    }
}

@end
