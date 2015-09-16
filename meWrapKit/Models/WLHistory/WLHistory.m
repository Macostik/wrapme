//
//  WLGroupedSet.m
//  meWrap
//
//  Created by Ravenpod on 7/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLHistory.h"
#import "WLCandy+Extended.h"
#import "WLEntry+Extended.h"
#import "NSDate+Formatting.h"
#import "WLCollections.h"
#import "NSDate+Additions.h"
#import "WLEntryNotifier.h"
#import "WLPaginatedRequest+Defined.h"
#import "WLSession.h"

@interface WLHistory () <WLEntryNotifyReceiver, WLBroadcastReceiver>

@property (weak, nonatomic) WLWrap* wrap;

@end

@implementation WLHistory

+ (instancetype)historyWithWrap:(WLWrap*)wrap {
    return [self historyWithWrap:wrap checkCompletion:NO];
}

+ (instancetype)historyWithWrap:(WLWrap *)wrap checkCompletion:(BOOL)checkCompletion {
    WLHistory *history = [[self alloc] init];
    history.checkCompletion = checkCompletion;
    [history addEntries:wrap.candies];
    history.request = [WLPaginatedRequest wrap:wrap contentType:WLWrapContentTypePaginated];
    history.wrap = wrap;
    return history;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSSystemTimeZoneDidChangeNotification object:nil];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[WLCandy notifier] addReceiver:self];
        self.sortComparator = comparatorByDate;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(systemTimeZoneChanged:) name:NSSystemTimeZoneDidChangeNotification object:nil];
    }
    return self;
}

- (void)systemTimeZoneChanged:(NSNotification*)notification {
    if (self.wrap.valid) {
        [self performSelector:@selector(resetEntries:) withObject:self.wrap.candies afterDelay:0.0f];
    }
}

- (void)resetEntries:(NSSet *)entries {
    [self clear];
    [self addEntries:entries];
}

- (BOOL)addEntries:(NSSet *)entries {
    BOOL candyAdded = NO;
    BOOL itemAdded = NO;
    NSMutableSet* entriesCopy = [entries mutableCopy];
    while (entriesCopy.nonempty) {
        NSDate* date = [[entriesCopy anyObject] createdAt];
        NSDate* beginOfDay = [date beginOfDay];
        NSDate* endOfDay = [date endOfDay];
        WLHistoryItem* group = [self itemForDate:beginOfDay];
        if (!group.entries.nonempty) {
            itemAdded = YES;
        }
        NSSet* dayEntries = [entriesCopy selects:^BOOL(WLCandy *candy) {
            NSDate *createdAt = [candy createdAt];
            if (date == nil) return createdAt == nil;
            NSTimeInterval timestamp = createdAt.timestamp;
            return timestamp >= beginOfDay.timestamp && timestamp <= endOfDay.timestamp;
        }];
        if ([group addEntries:dayEntries]) {
            candyAdded = YES;
        }
        [entriesCopy removes:dayEntries];
        
        if  (self.checkCompletion) {
            group.completed = group.entries.count < WLSession.pageSize;
        }
    }
    if (itemAdded) {
        [self.entries sort:self.sortComparator];
        [self didChange];
    }
    return candyAdded;
}

- (BOOL)addEntry:(WLCandy*)candy {
    WLHistoryItem* group = [self itemForDate:candy.createdAt.beginOfDay];
    if (!group.entries.nonempty) {
        [self.entries sort:self.sortComparator];
        [self didChange];
    }
    if ([group addEntry:candy]) {
        if ([candy.contributor isCurrentUser]) group.offset = CGPointZero;
        return YES;
    }
    return NO;
}

- (void)removeEntry:(id)entry {
    __block BOOL removed = NO;
    [self.entries removeSelectively:^BOOL(WLHistoryItem* group) {
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
        [self didChange];
    }
}

- (void)clear {
    [self.entries removeAllObjects];
}

- (void)sort:(WLCandy*)candy {
    WLHistoryItem* item = [self itemForDate:candy.createdAt.beginOfDay];
    if ([item.entries containsObject:candy]) {
        [item sort];
    } else {
        WLHistoryItem *_item = [self itemWithCandy:candy];
        if (_item) {
            [_item.entries removeObject:candy];
            if (_item.entries.nonempty) {
                [self.entries remove:_item];
            }
        }
        [item addEntry:candy];
        [self didChange];
    }
}

- (void)sort {
    for (WLHistoryItem* group in self.entries) {
        [group sort];
    }
}

- (WLHistoryItem *)itemWithCandy:(WLCandy *)candy {
    return [self.entries select:^BOOL(WLHistoryItem* item) {
        return [item.entries containsObject:candy];
    }];
}

- (WLHistoryItem *)itemForDate:(NSDate *)date {
    WLHistoryItem* item = [self.entries select:^BOOL(WLHistoryItem* item) {
        return item.date.timestamp == date.timestamp;
    }];
    if (!item) {
        item = [[WLHistoryItem alloc] init];
        item.history = self;
        item.date = date;
        [self.entries addObject:item];
    }
    return item;
}

- (void)handleResponse:(NSSet *)entries {
    NSMutableSet *candies = [self.wrap.candies mutableCopy];
    for (WLHistoryItem *item in self.entries) {
        [candies minusSet:item.entries.set];
    }
    [super handleResponse:candies];
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier didAddEntry:(WLCandy *)candy {
    [self addEntry:candy];
    if  ([candy.contributor isCurrentUser]) [self didChange];
}

- (void)notifier:(WLEntryNotifier *)notifier willDeleteEntry:(WLCandy *)candy {
    [self removeEntry:candy];
}

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLCandy *)candy {
    [self sort:candy];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return self.wrap == entry.container;
}

- (NSInteger)broadcasterOrderPriority:(WLBroadcaster *)broadcaster {
    return WLBroadcastReceiverOrderPriorityPrimary;
}

@end
