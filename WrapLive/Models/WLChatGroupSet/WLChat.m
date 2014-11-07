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

@implementation WLChat

- (instancetype)init {
    self = [super init];
    if (self) {
        self.typingUsers = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

- (void)addTypingUser:(WLUser *)user {
    if (![self.typingUsers containsObject:user]) {
        [self.typingUsers addObject:user];
        [self.delegate paginatedSetChanged:self];
    }
}

- (void)removeTypingUser:(WLUser *)user {
    if ([self.typingUsers containsObject:user]) {
        [self.typingUsers removeObject:user];
        [self.delegate paginatedSetChanged:self];
    }
}

- (void)addMessage:(WLMessage *)message {
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

@end

@implementation WLPaginatedSet (WLChatGroupSet)

- (NSDate *)date {
    return [self.entries.firstObject createdAt];
}

@end
