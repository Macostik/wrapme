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
        group = [self groupByUser:contributor paginationDown:flag];
        [messagesCopy enumerateObjectsUsingBlock:^(WLMessage *message, NSUInteger idx, BOOL *stop) {
            if ([message.contributor isEqualToEntry:contributor]) {
                [group.entries addObject:message];
                added = YES;
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

- (WLPaginatedSet *)groupByUser:(WLUser *)user paginationDown:(BOOL)flag {
    WLPaginatedSet *group = [self.entries selectObject:^BOOL(WLPaginatedSet *item) {
        return [[item user] isEqualToEntry:user] &&
                [item isEqual: flag ? self.entries.firstObject : self.entries.lastObject];
    }];
    return group ? : [[WLPaginatedSet alloc] init];
}

@end






