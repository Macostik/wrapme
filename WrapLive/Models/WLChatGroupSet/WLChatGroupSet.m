//
//  WLChatGroupSet.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLChatGroupSet.h"
#import "NSDate+Formatting.h"
#import "NSMutableOrderedSet+Sorting.h"
#import "WLMessage.h"

@implementation WLChatGroupSet

- (void)addMessage:(WLMessage *)message {
    [self addMessageToCorrectGroup:message];
}

- (void)addMessageToCorrectGroup:(WLMessage *)message  {
    WLPaginatedSet *lastSubGroup = self.entries.firstObject;
    WLMessage *lastMessage = lastSubGroup.entries.lastObject;
    if (lastMessage.contributor != message.contributor || ![lastMessage.createdAt isSameDay:message.createdAt]) {
        WLPaginatedSet *subGroup = [[WLPaginatedSet alloc] init];
        [self.entries insertObject:subGroup atIndex:0];
        [subGroup addEntry:message];
    } else {
        [lastSubGroup.entries insertObject:message atIndex:0];
    }
}

- (BOOL)addMessages:(NSOrderedSet *)messages pullDownToRefresh:(BOOL)flag {
    __block BOOL added = NO;
    __block WLPaginatedSet *group = nil;
    NSMutableOrderedSet* messagesCopy = [messages mutableCopy];
    [messagesCopy sortByCreatedAt:YES];
    while (messagesCopy.nonempty) {
        WLUser *contributor = [[messagesCopy firstObject] contributor];
        NSDate *date = [[messagesCopy firstObject] createdAt];
        group = [self groupByUser:contributor byDate:date andPaginationDownFlag:flag];
        [messagesCopy enumerateObjectsUsingBlock:^(WLMessage *message, NSUInteger idx, BOOL *stop) {
            if ([message.contributor isEqualToEntry:contributor]) {
                if ([group date] == nil) {
                   [group.entries addObject:message];
                    added = YES;
                } else if ([date isSameDay:message.createdAt]) {
                    [group.entries addObject:message];
                    added = YES;
                } else {
                    *stop = YES;
                }
            } else {
                *stop = YES;
            }
        }];
        
        [self.entries addObject:group];
        [messagesCopy minusOrderedSet:group.entries];
    }
    if (added) {
        [self sort];
    }
    return added;
}

- (void)sort {
    [self.entries sort:comparatorByDate descending:YES];
}

- (void)resetEntries:(NSOrderedSet *)entries {
    [self.entries removeAllObjects];
    [self addMessages:entries pullDownToRefresh:NO];
    [self.delegate paginatedSetChanged:self];
}

- (WLPaginatedSet *)groupByUser:(WLUser *)user byDate:(NSDate *)date andPaginationDownFlag:(BOOL)flag {
    WLPaginatedSet *group = flag ? self.entries.firstObject : self.entries.lastObject;
    if ([group.entries.firstObject contributor] == user && [group date] != nil && [[group date] isSameDay:date]) {
        return group;
    }
    return [[WLPaginatedSet alloc] init];
}

@end

@implementation WLPaginatedSet (WLChatGroupSet)

- (NSDate *)date {
    return [self.entries.firstObject createdAt];
}

@end
