//
//  WLGroupedSet.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLHistory.h"
#import "WLCandy+Extended.h"
#import "WLEntry+Extended.h"
#import "NSDate+Formatting.h"
#import "NSOrderedSet+Additions.h"
#import "NSDate+Additions.h"
#import "WLWrapRequest.h"
#import "WLEntryNotifier.h"

@interface WLHistory () <WLEntryNotifyReceiver, WLBroadcastReceiver>

@property (weak, nonatomic) WLWrap* wrap;

@end

@implementation WLHistory

+ (instancetype)historyWithWrap:(WLWrap*)wrap {
    WLHistory *history = [[self alloc] init];
    [history addEntries:wrap.candies];
    WLWrapRequest* wrapRequest = [WLWrapRequest request:wrap];
    wrapRequest.contentType = WLWrapContentTypePaginated;
    history.request = wrapRequest;
    history.wrap = wrap;
    return history;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[WLCandy notifier] addReceiver:self];
        self.sortComparator = comparatorByDate;
    }
    return self;
}

- (void)resetEntries:(NSOrderedSet *)entries {
    [self clear];
    [self addEntries:entries];
}

- (BOOL)addEntries:(NSOrderedSet *)entries {
    BOOL added = NO;
    NSMutableOrderedSet* entriesCopy = [entries mutableCopy];
    while (entriesCopy.nonempty) {
        NSDate* date = [[entriesCopy firstObject] createdAt];
        NSDateComponents* components = [date dayComponents];
        WLHistoryItem* group = [self itemForDate:date create:YES];
        NSOrderedSet* dayEntries = [entriesCopy selectObjects:^BOOL(id item) {
            if (components == nil) {
                return [item createdAt] == nil;
            }
            return [[item createdAt] isSameDayComponents:components];
        }];
        if ([group addEntries:dayEntries]) {
            added = YES;
        }
        [entriesCopy minusOrderedSet:dayEntries];
        
        group.completed = group.entries.count < WLPageSize;
    }
    if (added) {
        [self.entries sort:self.sortComparator];
    }
    return added;
}

- (BOOL)addEntry:(WLCandy*)candy {
    WLHistoryItem* group = [self itemForDate:candy.createdAt create:YES];
    if ([group addEntry:candy]) {
        [self.entries sort:self.sortComparator];
        return YES;
    }
    return NO;
}

- (void)removeEntry:(id)entry {
    __block BOOL removed = NO;
    [self.entries removeObjectsWhileEnumerating:^BOOL(WLHistoryItem* group) {
        if ([group.entries containsObject:entry]) {
            [group.entries removeObject:entry];
            removed = YES;
            if (group.entries.nonempty) {
                return NO;
            }
            return YES;
        }
        return NO;
    }];
    if (removed) {
        [self.delegate paginatedSetChanged:self];
    }
}

- (void)clear {
    [self.entries removeAllObjects];
}

- (void)sort:(WLCandy*)candy {
    WLHistoryItem* group = [self itemForDate:candy.createdAt create:YES];
    if ([group.entries containsObject:candy]) {
        [group sort];
        return;
    }
    [self.entries removeObjectsWhileEnumerating:^BOOL(WLHistoryItem* group) {
        if ([group.entries containsObject:candy]) {
            [group.entries removeObject:candy];
            if (group.entries.nonempty) {
                return NO;
            }
            return YES;
        }
        return NO;
    }];
    [group addEntry:candy];
    [self.delegate paginatedSetChanged:self];
}

- (void)sort {
    for (WLHistoryItem* group in self.entries) {
        [group sort];
    }
}

- (WLHistoryItem *)itemWithCandy:(WLCandy *)candy {
    return [self.entries selectObject:^BOOL(WLHistoryItem* item) {
        return [item.entries containsObject:candy];
    }];
}

- (WLHistoryItem *)itemForDate:(NSDate *)date {
    return [self.entries selectObject:^BOOL(WLHistoryItem* item) {
        return [item.date isSameDay:date];
    }];
}

- (WLHistoryItem *)itemForDate:(NSDate *)date create:(BOOL)create {
    WLHistoryItem* item = [self.entries selectObject:^BOOL(WLHistoryItem* item) {
        return [item.date isSameDay:date];
    }];
    if (!item && create) {
        item = [[WLHistoryItem alloc] init];
        item.date = date;
        [self.entries addObject:item];
        [self.delegate paginatedSetChanged:self];
    }
    return item;
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier candyAdded:(WLCandy *)candy {
    [self addEntry:candy];
}

- (void)notifier:(WLEntryNotifier *)notifier candyDeleted:(WLCandy *)candy {
    [self removeEntry:candy];
}

- (void)notifier:(WLEntryNotifier *)notifier candyUpdated:(WLCandy *)candy {
    [self sort:candy];
}

- (WLWrap *)notifierPreferredWrap:(WLEntryNotifier *)notifier {
    return self.wrap;
}

- (NSNumber *)peferedOrderEntry:(WLBroadcaster *)broadcaster {
    return @(1);
}

@end
