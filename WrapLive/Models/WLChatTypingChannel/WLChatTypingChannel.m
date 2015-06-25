//
//  WLChatTypingChannel.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/7/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLChatTypingChannel.h"

static NSString *WLChatTypingChannelTypingKey = @"typing";
static NSString *WLChatTypingChannelSendMessageKey = @"send_message";

@implementation WLChatTypingChannel

+ (instancetype)channelWithWrap:(WLWrap *)wrap {
    WLChatTypingChannel* channel = [self channelWithName:wrap.identifier shouldObservePresence:YES];
    __weak typeof(channel)weakChannel = channel;
    [channel observePresense:^(PNPresenceEvent *event) {
        WLUser* user = [WLUser entry:event.client.identifier];
        if ([user isCurrentUser]) {
            return;
        }
        if (event.type == PNPresenceEventStateChanged) {
            [weakChannel handleClientState:[event.client stateForChannel:weakChannel.channel] user:user];
        } else if (event.type == PNPresenceEventTimeout) {
            [weakChannel.delegate chatTypingChannel:weakChannel didEndTyping:user];
        }
    }];
    return channel;
}

- (void)observePresense:(PNClientPresenceEventHandlingBlock)presenseEventHandler {
    [super observePresense:presenseEventHandler];
    [self fetchParticipants];
}

- (void)fetchParticipants {
    __weak typeof(self)weakSelf = self;
    [self participants:^(NSArray *participants) {
        for (PNClient* client in participants) {
            WLUser* user = [WLUser entry:client.identifier];
            if ([user isCurrentUser]) {
                continue;
            }
            NSDictionary *data = [client stateForChannel:weakSelf.channel];
            if ([data[WLChatTypingChannelTypingKey] boolValue]) {
                [weakSelf.delegate chatTypingChannel:weakSelf didBeginTyping:user];
            }
        }
    }];
}

- (void)handleClientState:(NSDictionary*)state user:(WLUser*)user {
    if (state[WLChatTypingChannelTypingKey] == nil) return;
    BOOL typing = [state[WLChatTypingChannelTypingKey] boolValue];
    if (typing) {
        [self.delegate chatTypingChannel:self didBeginTyping:user];
    } else {
        [self.delegate chatTypingChannel:self didEndTyping:user];
    }
}

- (void)sendTyping:(BOOL)typing sendMessage:(BOOL)sendMessage {
    [self changeState:@{WLChatTypingChannelTypingKey : @(typing),WLChatTypingChannelSendMessageKey : @(sendMessage)}];
}

- (void)beginTyping {
    [self sendTyping:YES sendMessage:NO];
}

- (void)endTyping:(BOOL)sendMessage {
    [self sendTyping:NO sendMessage:sendMessage];
}

@end
