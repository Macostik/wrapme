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
    WLGroup *group = [self groupForDate:message.createdAt];
    [self addMessage:message inCorrectGroup:group];
}

- (WLGroup *)groupForDate:(NSDate *)date {
    WLGroup* group = [self.entries selectObject:^BOOL(WLGroup* item) {
        return [item.date isSameDay:date];
    }];
    if (!group) {
        group = [WLGroup group];
        group.date = date;
        [self.entries addObject:group];
        [self.delegate paginatedSetChanged:self];
    }
    return group;
}

- (void)addMessage:(WLMessage *)message inCorrectGroup:(WLGroup *)group {
    WLGroup *lastSubGroup = group.entries.firstObject;
    WLMessage *lastMessage = lastSubGroup.entries.lastObject;
    if (lastMessage.contributor != message.contributor) {
        WLGroup *subGroup = [WLGroup group];
        subGroup.date = message.createdAt;
        [group.entries insertObject:subGroup atIndex:0];
        [subGroup addEntry:message];
    } else {
        [lastSubGroup addEntry:message];
    }
}

- (void)addMessages:(NSOrderedSet *)messages {
    __weak __typeof(self)weakSelf = self;
    [self sort];
    [messages all:^(WLMessage *message) {
        [weakSelf addMessage:message];
    }];
}

@end

