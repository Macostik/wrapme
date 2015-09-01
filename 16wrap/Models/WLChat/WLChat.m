//
//  WLChatGroupSet.m
//  moji
//
//  Created by Yura Granchenko on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLChat.h"
#import "WLNotificationSubscription.h"
#import "WLToast.h"

static NSString *WLChatTypingChannelTypingKey = @"typing";

@interface WLChat () <WLNotificationSubscriptionDelegate>

@property (strong, nonatomic) WLNotificationSubscription* subscription;

@end

@implementation WLChat

@dynamic delegate;

+ (instancetype)chatWithWrap:(WLWrap *)wrap {
    WLChat* chat = [[self alloc] init];
    chat.sortComparator = comparatorByCreatedAt;
    chat.wrap = wrap;
    return chat;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.unreadMessages = [NSMutableOrderedSet orderedSet];
        self.readMessages = [NSMutableOrderedSet orderedSet];
        self.messagesWithDay = [NSHashTable weakObjectsHashTable];
        self.messagesWithName = [NSHashTable weakObjectsHashTable];
        self.typingUsers = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    [self resetEntries:wrap.messages];
    if (wrap) {
        __weak typeof(self)weakSelf = self;
        run_after_asap(^{
            weakSelf.subscription = [WLNotificationSubscription subscription:wrap.identifier presence:YES];
            weakSelf.subscription.delegate = weakSelf;
            [weakSelf.subscription hereNow:^(NSArray *uuids) {
                for (NSDictionary* uuid in uuids) {
                    WLUser* user = [WLUser entry:uuid[@"uuid"]];
                    if ([user isCurrentUser]) {
                        continue;
                    }
                    if ([uuid[@"state"][WLChatTypingChannelTypingKey] boolValue]) {
                        [weakSelf didBeginTyping:user];
                    }
                }
            }];
        });
    } else {
        self.subscription = nil;
    }
}

- (void)addTypingUser:(WLUser *)user {
    if (![self.typingUsers containsObject:user]) {
        [self.typingUsers addObject:user];
        self.typingNames = [self namesOfUsers:self.typingUsers];
    }
}

- (void)removeTypingUser:(WLUser *)user {
    if ([self.typingUsers containsObject:user]) {
        [self.typingUsers removeObject:user];
        self.typingNames = [self namesOfUsers:self.typingUsers];
    }
}

- (NSString *)namesOfUsers:(NSMutableOrderedSet*)users {
    if (!users.nonempty) return nil;
    if (users.count == 1) {
        return [NSString stringWithFormat:WLLS(@"formatted_is_typing"), [(WLUser*)[users lastObject] name]];
    } else if (users.count == 2) {
        return [NSString stringWithFormat:WLLS(@"formatted_and_are_typing"), [(WLUser*)users[0] name], [(WLUser*)users[1] name]];
    } else {
        WLUser* lastUser = [users lastObject];
        NSString* names = [[[[users array] remove:lastUser] valueForKey:@"name"] componentsJoinedByString:@", "];
        return [NSString stringWithFormat:WLLS(@"formatted_and_are_typing"), names, lastUser.name];
    }
}

- (BOOL)addEntry:(WLMessage*)message {
    WLUser *contributor = message.contributor;
    if ([self.typingUsers containsObject:contributor]) {
        [self.typingUsers removeObject:contributor];
    }
    if (![super addEntry:message]) {
        [self sort];
    }
    return YES;
}

#pragma mark - WLChatTypingChannelDelegate

- (void)didBeginTyping:(WLUser *)user {
    if (![user isCurrentUser]) {
        if (!user.name.nonempty || !user.picture.large.nonempty) {
            __weak __typeof(self)weakSelf = self;
            [self.wrap addContributorsObject:user];
            [[WLAPIRequest user:user] send:^(WLUser *_user) {
                [weakSelf addTypingUser:_user];
                if ([weakSelf.delegate respondsToSelector:@selector(chat:didBeginTyping:)]) {
                    [weakSelf.delegate chat:weakSelf didBeginTyping:_user];
                }
            } failure:^(NSError *error) {
                [WLToast showWithMessage:WLLS(@"data_invalid")];
            }];
        } else {
            [self addTypingUser:user];
        }
        
        if ([self.delegate respondsToSelector:@selector(chat:didBeginTyping:)]) {
            [self.delegate chat:self didBeginTyping:user];
        }
    }
}

- (void)didEndTyping:(WLUser *)user {
    if (![user isCurrentUser]) {
        [self removeTypingUser:user];
        if ([self.delegate respondsToSelector:@selector(chat:didEndTyping:)]) {
            [self.delegate chat:self didEndTyping:user];
        }
    }
}

- (void)didChange {
    
    NSHashTable *messagesWithName = [NSHashTable weakObjectsHashTable];
    [_unreadMessages removeAllObjects];
    [_messagesWithDay removeAllObjects];
    NSOrderedSet *messages = self.entries;
    for (WLMessage *message in messages) {
        
        if (message.unread) {
            [_unreadMessages addObject:message];
        }
        
        NSUInteger index = [messages indexOfObject:message];
        WLMessage* previousMessage = [messages tryAt:index + 1];
        BOOL showDay = previousMessage == nil || ![previousMessage.createdAt isSameDay:message.createdAt];
        if (showDay) {
            [_messagesWithDay addObject:message];
            [messagesWithName addObject:message];
            continue;
        }
        
        if (previousMessage.contributor != message.contributor) {
            [messagesWithName addObject:message];
        }
    }
    
    if (_messagesWithName && ![_messagesWithName isEqualToHashTable:messagesWithName]) {
        _messagesWithName = messagesWithName;
        if ([self.delegate respondsToSelector:@selector(chatDidChangeMessagesWithName:)]) {
            [self.delegate chatDidChangeMessagesWithName:self];
        }
    } else {
        _messagesWithName = messagesWithName;
    }
    
    [super didChange];
}

// MARK: - WLNotificationSubscriptionDelegate

- (void)notificationSubscription:(WLNotificationSubscription *)subscription didReceivePresenceEvent:(PNPresenceEventData *)event {
    WLUser* user = [WLUser entry:event.presence.uuid];
    if ([user isCurrentUser]) {
        return;
    }
    if ([event.presenceEvent isEqualToString:@"state-change"]) {
        [self handleClientState:event.presence.state user:user];
    } else if ([event.presenceEvent isEqualToString:@"leave"] || [event.presenceEvent isEqualToString:@"timeout"]) {
        [self didEndTyping:user];
    }
}

- (void)handleClientState:(NSDictionary*)state user:(WLUser*)user {
    if (state[WLChatTypingChannelTypingKey] == nil) return;
    BOOL typing = [state[WLChatTypingChannelTypingKey] boolValue];
    if (typing) {
        [self didBeginTyping:user];
    } else {
        [self didEndTyping:user];
    }
}

- (void)sendTyping:(BOOL)typing {
    [self.subscription changeState:@{WLChatTypingChannelTypingKey : @(typing)}];
}

- (void)beginTyping {
    [self sendTyping:YES];
}

- (void)endTyping {
    [self sendTyping:NO];
}

@end
