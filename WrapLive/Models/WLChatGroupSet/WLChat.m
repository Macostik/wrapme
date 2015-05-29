//
//  WLChatGroupSet.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLChat.h"
#import "NSMutableOrderedSet+Sorting.h"

@interface WLChat () <WLChatTypingChannelDelegate>

@end

@implementation WLChat

@dynamic delegate;

- (void)dealloc {
    [self.typingChannel removeObserving];
}

+ (instancetype)chatWithWrap:(WLWrap *)wrap {
    WLChat* chat = [[self alloc] init];
    chat.sortComparator = comparatorByCreatedAt;
    chat.wrap = wrap;
    return chat;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.messagesWithDay = [NSHashTable weakObjectsHashTable];
        self.messagesWithName = [NSHashTable weakObjectsHashTable];
        self.typingUsers = [NSMutableOrderedSet orderedSet];
        self.sendMessageUsers = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    [self resetEntries:wrap.messages];
    [self setUnreadMessages];
    if (wrap) {
        self.typingChannel = [WLChatTypingChannel channelWithWrap:wrap];
        self.typingChannel.delegate = self;
    } else {
        self.typingChannel = nil;
    }
}

- (void)setUnreadMessages {
    NSDate *lastUnread = _wrap.lastUnread;
    NSMutableOrderedSet *unreadMessages = nil;
    if (lastUnread) {
        unreadMessages = [self.entries objectsWhere:@"createdAt > %@", lastUnread];
    } else {
        unreadMessages = [self.entries objectsWhere:@"unread == YES"];
    }
    if (unreadMessages.nonempty) {
        unreadMessages = [unreadMessages mutableCopy];
        __block BOOL isMessagesFromCurrentUser = NO;
        [unreadMessages removeObjectsWhileEnumerating:^BOOL(WLMessage *message) {
            if ([message.contributor isCurrentUser]) {
                isMessagesFromCurrentUser = YES;
                return YES;
            } else {
                return isMessagesFromCurrentUser;
            }
        }];
    }
    self.unreadMessages = unreadMessages;
}

- (void)addTypingUser:(WLUser *)user {
    if (![self.typingUsers containsObject:user]) {
        [self.typingUsers addObject:user];
        self.typingNames = [self namesOfUsers:self.typingUsers];
        [self didChange];
    }
}

- (void)removeTypingUser:(WLUser *)user {
    if ([self.typingUsers containsObject:user]) {
        [self.typingUsers removeObject:user];
        self.typingNames = [self namesOfUsers:self.typingUsers];
        [self didChange];
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
        NSString* names = [[[[users array] arrayByRemovingObject:lastUser] valueForKey:@"name"] componentsJoinedByString:@", "];
        return [NSString stringWithFormat:WLLS(@"formatted_and_are_typing"), names, lastUser.name];
    }
}

- (BOOL)addEntry:(WLMessage*)message {
    WLUser *contributor = message.contributor;
    if ([self.typingUsers containsObject:contributor]) {
        [self.typingUsers removeObject:contributor];
    }
    if ([self.sendMessageUsers containsObject:contributor]) {
        [self.sendMessageUsers removeObject:contributor];
    }
    if (![super addEntry:message]) {
        [self sort];
    }
    return YES;
}

- (BOOL)showTypingView {
    return self.typingUsers.nonempty || self.sendMessageUsers.nonempty;
}

#pragma mark - WLChatTypingChannelDelegate

- (void)chatTypingChannel:(WLChatTypingChannel *)channel didBeginTyping:(WLUser *)user {
    if (![user isCurrentUser]) {
        [self addTypingUser:user];
        if ([self.delegate respondsToSelector:@selector(chat:didBeginTyping:)]) {
            [self.delegate chat:self didBeginTyping:user];
        }
    }
}

- (void)chatTypingChannel:(WLChatTypingChannel *)channel didEndTyping:(WLUser *)user andSendMessage:(BOOL)sendMessage {
    if (![user isCurrentUser]) {
        if (sendMessage) {
            [self.sendMessageUsers addObject:user];
        }
        [self removeTypingUser:user];
        if ([self.delegate respondsToSelector:@selector(chat:didEndTyping:andSendMessage:)]) {
            [self.delegate chat:self didEndTyping:user andSendMessage:sendMessage];
        }
    }
}

- (void)didChange {
    
    NSHashTable *messagesWithName = [NSHashTable weakObjectsHashTable];
    
    [_messagesWithDay removeAllObjects];
    NSOrderedSet *messages = self.entries;
    for (WLMessage *message in messages) {
        NSUInteger index = [messages indexOfObject:message];
        WLMessage* previousMessage = [messages tryObjectAtIndex:index + 1];
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

@end

@implementation WLPaginatedSet (WLChatGroupSet)

- (NSDate *)date {
    return [self.entries.firstObject createdAt];
}

@end
