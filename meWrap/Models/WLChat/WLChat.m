//
//  WLChatGroupSet.m
//  meWrap
//
//  Created by Yura Granchenko on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLChat.h"
#import "WLToast.h"
#import "WLAPIRequest+Defined.h"

static NSString *WLChatTypingChannelTypingKey = @"typing";

@interface WLChat () <NotificationSubscriptionDelegate>

@property (strong, nonatomic) NotificationSubscription* subscription;

@end

@implementation WLChat

@dynamic delegate;

+ (instancetype)chatWithWrap:(Wrap *)wrap {
    WLChat* chat = [[self alloc] init];
    chat.sortComparator = comparatorByCreatedAt;
    chat.sortDescending = NO;
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
        self.groupMessages = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

- (void)setWrap:(Wrap *)wrap {
    _wrap = wrap;
    [self resetEntries:wrap.messages];
    if (wrap) {
        __weak typeof(self)weakSelf = self;
        run_after_asap(^{
            weakSelf.subscription = [[NotificationSubscription alloc] initWithName:wrap.identifier isGroup:NO observePresence:YES];
            weakSelf.subscription.delegate = weakSelf;
            [weakSelf.subscription hereNow:^(NSArray *uuids) {
                for (NSDictionary* uuid in uuids) {
                    User *user = [User entry:uuid[@"uuid"]];
                    if ([user current]) {
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

- (void)addTypingUser:(User *)user {
    if (![self.typingUsers containsObject:user]) {
        [self.typingUsers addObject:user];
        self.typingNames = [self namesOfUsers:self.typingUsers];
    }
}

- (void)removeTypingUser:(User *)user {
    if ([self.typingUsers containsObject:user]) {
        [self.typingUsers removeObject:user];
        self.typingNames = [self namesOfUsers:self.typingUsers];
    }
}

- (NSString *)namesOfUsers:(NSMutableOrderedSet*)users {
    if (!users.nonempty) return nil;
    if (users.count == 1) {
        return [NSString stringWithFormat:@"formatted_is_typing".ls, [(User *)[users lastObject] name]];
    } else if (users.count == 2) {
        return [NSString stringWithFormat:@"formatted_and_are_typing".ls, [(User *)users[0] name], [(User *)users[1] name]];
    } else {
        User *lastUser = [users lastObject];
        NSString* names = [[[[users array] remove:lastUser] valueForKey:@"name"] componentsJoinedByString:@", "];
        return [NSString stringWithFormat:@"formatted_and_are_typing".ls, names, lastUser.name];
    }
}

- (BOOL)addEntry:(Message*)message {
    User *contributor = message.contributor;
    if ([self.typingUsers containsObject:contributor]) {
        [self.typingUsers removeObject:contributor];
    }
    if (![super addEntry:message]) {
        [self sort];
    }
    return YES;
}

#pragma mark - WLChatTypingChannelDelegate

- (void)didBeginTyping:(User *)user {
    if (![user current]) {
        if (!user.name.nonempty || !user.picture.large.nonempty) {
            __weak __typeof(self)weakSelf = self;
            [[self.wrap mutableContributors] addObject:user];
            [[WLAPIRequest user:user] send:^(User *_user) {
                [weakSelf addTypingUser:_user];
                if ([weakSelf.delegate respondsToSelector:@selector(chat:didBeginTyping:)]) {
                    [weakSelf.delegate chat:weakSelf didBeginTyping:_user];
                }
            } failure:^(NSError *error) {
                [WLToast showWithMessage:@"data_invalid".ls];
            }];
        } else {
            [self addTypingUser:user];
        }
        
        if ([self.delegate respondsToSelector:@selector(chat:didBeginTyping:)]) {
            [self.delegate chat:self didBeginTyping:user];
        }
    }
}

- (void)didEndTyping:(User *)user {
    if (![user current]) {
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
    [_groupMessages removeAllObjects];
    NSOrderedSet *messages = self.entries;
    for (Message *message in messages) {
        
        if (message.unread) {
            [_unreadMessages addObject:message];
        }
        
        NSUInteger index = [messages indexOfObject:message];
        Message *previousMessage = [messages tryAt:index - 1];
        BOOL showDay = previousMessage == nil || ![previousMessage.createdAt isSameDay:message.createdAt];
        if (showDay) {
            [_messagesWithDay addObject:message];
            if (!message.contributor.current) [messagesWithName addObject:message];
            [self.groupMessages addObject:message];
            continue;
        }
        
        if (previousMessage.contributor != message.contributor) {
            if (!message.contributor.current) [messagesWithName addObject:message];
            [self.groupMessages addObject:message];
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

// MARK: - NotificationSubscriptionDelegate

- (void)notificationSubscription:(NotificationSubscription *)subscription didReceivePresenceEvent:(PNPresenceEventResult * _Nonnull)event {
    User *user = [User entry:event.data.presence.uuid];
    if ([user current]) {
        return;
    }
    if ([event.data.presenceEvent isEqualToString:@"state-change"]) {
        [self handleClientState:event.data.presence.state user:user];
    } else if ([event.data.presenceEvent isEqualToString:@"leave"] || [event.data.presenceEvent isEqualToString:@"timeout"]) {
        if ([self.typingUsers containsObject:user]) {
            [self didEndTyping:user];
        }
    }
}

- (void)handleClientState:(NSDictionary*)state user:(User *)user {
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

- (void)markAsRead {
    [self.readMessages all:^(Message *message) {
        [message markAsRead];
    }];
}

@end
