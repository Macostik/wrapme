//
//  WLChatGroupSet.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLChat.h"
#import "NSDate+Formatting.h"
#import "NSMutableOrderedSet+Sorting.h"
#import "WLMessage.h"

@interface WLChat () <WLChatTypingChannelDelegate>

@end

@implementation WLChat

- (void)dealloc {
    [self.typingChannel removeObserving];
}

+ (instancetype)chatWithWrap:(WLWrap *)wrap {
    WLChat* chat = [[self alloc] init];
    chat.wrap = wrap;
    return chat;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.typingUsers = [NSMutableOrderedSet orderedSet];
        self.sendMessageUsers = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    [self resetEntries:wrap.messages];
    self.typingChannel = [WLChatTypingChannel channelWithWrap:wrap];
    self.typingChannel.delegate = self;
}

- (void)addTypingUser:(WLUser *)user {
    if (![self.typingUsers containsObject:user]) {
        [self.typingUsers addObject:user];
        self.typingNames = [self namesOfUsers:self.typingUsers];
        [self.delegate paginatedSetChanged:self];
    }
}

- (void)removeTypingUser:(WLUser *)user {
    if ([self.typingUsers containsObject:user]) {
        [self.typingUsers removeObject:user];
        self.typingNames = [self namesOfUsers:self.typingUsers];
        [self.delegate paginatedSetChanged:self];
    }
}

- (NSString *)namesOfUsers:(NSMutableOrderedSet*)users {
    if (!users.nonempty) return nil;
    NSString* names = nil;
    if (users.count == 1) {
        names = [(WLUser*)[users lastObject] name];
    } else if (users.count == 2) {
        names = [NSString stringWithFormat:@"%@ and %@", [(WLUser*)users[0] name], [(WLUser*)users[1] name]];
    } else {
        WLUser* lastUser = [users lastObject];
        names = [[[[users array] arrayByRemovingObject:lastUser] valueForKey:@"name"] componentsJoinedByString:@", "];
        names = [names stringByAppendingFormat:@" and %@", lastUser.name];
    }
    return [names stringByAppendingString:@" is typing..."];
}

- (void)addMessage:(WLMessage *)message {
    WLUser *contributor = message.contributor;
    if ([self.typingUsers containsObject:contributor]) {
        [self.typingUsers removeObject:contributor];
    }
    if ([self.sendMessageUsers containsObject:contributor]) {
        [self.sendMessageUsers removeObject:contributor];
    }
    [[self addMessage:message isNewer:YES].entries sortByCreatedAt];
    [self.delegate paginatedSetChanged:self];
}

- (WLPaginatedSet*)addMessage:(WLMessage *)message isNewer:(BOOL)newer  {
    WLPaginatedSet *group = newer ? self.entries.firstObject : self.entries.lastObject;
    if (![self message:message canBeAddedToGroup:group]) {
        group = [[WLPaginatedSet alloc] init];
        if (newer) {
            [self.entries insertObject:group atIndex:0];
        } else {
            [self.entries addObject:group];
        }
    }
    [group.entries addObject:message];
    return group;
}

- (BOOL)addMessages:(NSOrderedSet *)messages isNewer:(BOOL)newer {
    if (!messages.nonempty) return NO;
    messages = [messages mutableCopy];
    [(NSMutableOrderedSet *)messages sortByCreatedAt:YES];
    for (WLMessage* message in messages) {
        [self addMessage:message isNewer:newer];
    }
    [self sort];
    [self.delegate paginatedSetChanged:self];
    return YES;
}

- (void)sort {
    [self.entries sort:comparatorByDate descending:YES];
}

- (void)resetEntries:(NSOrderedSet *)entries {
    [self.entries removeAllObjects];
    [self addMessages:entries isNewer:NO];
}

- (BOOL)message:(WLMessage*)message canBeAddedToGroup:(WLPaginatedSet*)group {
    if (group == nil) return NO;
    if (!group.entries.nonempty) return YES;
    if ([group.entries.firstObject contributor] != message.contributor) return NO;
    if (![[group date] isSameDay:message.createdAt]) return NO;
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

@end

@implementation WLPaginatedSet (WLChatGroupSet)

- (NSDate *)date {
    return [self.entries.firstObject createdAt];
}

@end
