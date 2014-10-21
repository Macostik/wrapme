//
//  WLChatGroupSet.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLChatGroupSet.h"
#import "NSDate+Formatting.h"

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

- (void)addMessages:(NSOrderedSet *)messages {
    __weak __typeof(self)weakSelf = self;
    [messages all:^(WLMessage *message) {
        [weakSelf addMessageToCorrectGroup:message];
    }];
}

- (void)sort {
    [self.entries sortedArrayUsingComparator:comparatorByDate];
}

- (void)resetEntries:(NSOrderedSet *)entries {
    [self.entries removeAllObjects];
    [self.entries unionOrderedSet:entries];
    [self.entries sort];
    [self.delegate paginatedSetChanged:self];
}

@end






