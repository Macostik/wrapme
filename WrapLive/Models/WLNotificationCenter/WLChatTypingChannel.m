//
//  WLChatTypingChannel.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/7/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLChatTypingChannel.h"
#import "WLEntryManager.h"

static NSString *WLChatTypingChannelTypingKey = @"typing";
static NSString *WLChatTypingChannelSendMessageKey = @"send_message";

@implementation WLChatTypingChannel

+ (instancetype)channelWithWrap:(WLWrap *)wrap {
    return [self channel:wrap.identifier subscribe:YES];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.supportPresense = YES;
        __weak typeof(self)weakSelf = self;
        [self setPresenseObserver:^(PNPresenceEvent *event) {
            WLUser* user = [WLUser entry:event.client.identifier];
            if ([user isCurrentUser]) {
                return;
            }
            if (event.type == PNPresenceEventStateChanged) {
                [weakSelf handleClientState:event.client.data user:user];
            } else if (event.type == PNPresenceEventTimeout) {
                [weakSelf.delegate chatTypingChannel:weakSelf didEndTyping:user andSendMessage:NO];
            }
        }];
    }
    return self;
}

- (void)enablePresense {
    [super enablePresense];
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
            [weakSelf handleClientState:client.data user:user];
        }
    }];
}

- (void)handleClientState:(NSDictionary*)state user:(WLUser*)user {
    if (state[WLChatTypingChannelTypingKey] == nil) return;
    BOOL typing = [state[WLChatTypingChannelTypingKey] boolValue];
    if (typing) {
        [self.delegate chatTypingChannel:self didBeginTyping:user];
    } else {
        BOOL sendMessage = [state boolForKey:WLChatTypingChannelSendMessageKey];
        [self.delegate chatTypingChannel:self didEndTyping:user andSendMessage:sendMessage];
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
