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

@interface WLNotificationChannel ()

@end

@implementation WLNotificationChannel

+ (instancetype)channelWithName:(NSString *)channelName {
    return [self channelWithName:channelName shouldObservePresence:NO];
}

+ (instancetype)channelWithName:(NSString *)channelName shouldObservePresence:(BOOL)observePresence {
    
    WLNotificationChannel *channel = [[self alloc] init];
    channel.channel = [PNChannel channelWithName:channelName shouldObservePresence:observePresence];
    [channel subscribe];
    return channel;
}

- (void)dealloc {
    [self unsubscribe];
}

- (void)removeObserving {
    [[PNObservationCenter defaultCenter] removeMessageReceiveObserver:self];
    [[PNObservationCenter defaultCenter] removePresenceEventObserver:self];
}

- (BOOL)subscribed {
    return [PubNub isSubscribedOn:self.channel];
}

- (void)subscribe {
    if (self.subscribed || !self.channel) {
        return;
    }
    [PubNub subscribeOn:@[self.channel]];
}

- (void)unsubscribe {
    if (!self.subscribed || !self.channel) {
        return;
    }
    [PubNub unsubscribeFrom:@[self.channel]];
}

- (void)enableAPNS {
    __weak typeof(self)weakSelf = self;
    [WLNotificationCenter deviceToken:^(NSData *data) {
        [PubNub requestParticipantsListWithCompletionBlock:^(PNHereNow *hereNow, NSArray *channels, PNError *error) {
            if (!error) {
                for (PNChannel *channel in [hereNow channels]) {
                    if (![channel.name isEqualToString:weakSelf.channel.name]) {
                        [PubNub disablePushNotificationsOnChannel:channel withDevicePushToken:data];
                    }
                }
            }
        }];
        [PubNub enablePushNotificationsOnChannel:weakSelf.channel withDevicePushToken:data];
    }];
}

- (void)observeMessages:(PubNubMessageBlock)messageHandler {
    __weak typeof(self)weakSelf = self;
    self.messageHandler = messageHandler;
    [[PNObservationCenter defaultCenter] addMessageReceiveObserver:self withBlock:^(PNMessage *message) {
        if (message.channel == weakSelf.channel && weakSelf.messageHandler) {
            weakSelf.messageHandler(message);
        }
    }];
}

- (void)observePresense:(PNClientPresenceEventHandlingBlock)presenseEventHandler {
    __weak typeof(self)weakSelf = self;
    self.presenseEventHandler = presenseEventHandler;
    [[PNObservationCenter defaultCenter] addPresenceEventObserver:self withBlock:^(PNPresenceEvent *event) {
        if (event.channel == weakSelf.channel && weakSelf.presenseEventHandler) {
            weakSelf.presenseEventHandler(event);
        }
    }];
}

- (void)send:(NSDictionary *)message {
    if (self.subscribed) {
        [PubNub sendMessage:message toChannel:self.channel];
    }
}

- (void)changeState:(NSDictionary*)state {
    [PubNub updateClientState:[WLUser currentUser].identifier state:state forObject:self.channel];
}

- (void)participants:(WLArrayBlock)completion {
    if (self.subscribed && self.channel) {
        __weak typeof(self)weakSelf = self;
        [PubNub requestParticipantsListFor:@[self.channel] clientIdentifiersRequired:YES clientState:YES withCompletionBlock:^(PNHereNow *hereNow, NSArray *channels, PNError *error) {
            if (!error && completion) {
                completion([hereNow participantsForChannel:weakSelf.channel]);
            }
        }];
    }
}

@end
