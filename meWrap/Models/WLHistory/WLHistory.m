//
//  WLGroupedSet.m
//  meWrap
//
//  Created by Ravenpod on 7/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLHistory.h"
#import "WLCollections.h"
#import "WLPaginatedRequest+Defined.h"

@interface WLHistory () <EntryNotifying, WLBroadcastReceiver>

@property (weak, nonatomic) Wrap *wrap;

@end

@implementation WLHistory

+ (instancetype)historyWithWrap:(Wrap *)wrap {
    WLHistory *history = [[self alloc] init];
    history.wrap = wrap;
    [history fetchCandies];
    history.request = [WLPaginatedRequest candies:wrap];
    return history;
}

- (void)fetchCandies {
    [self.entries removeAllObjects];
    [self.entries addObjectsFromArray:self.wrap.historyCandies];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.paginationDateKeyPath = @"createdAt";
        [[Candy notifier] addReceiver:self];
        self.sortComparator = comparatorByCreatedAt;
    }
    return self;
}

- (void)resetEntries:(NSSet *)entries {
    [self fetchCandies];
    [self didChange];
}

// MARK: - EntryNotifying

- (void)notifier:(EntryNotifier *)notifier didAddEntry:(Candy *)candy {
    [self addEntry:candy];
    if  ([candy.contributor current]) [self didChange];
}

- (void)notifier:(EntryNotifier *)notifier willDeleteEntry:(Candy *)candy {
    [self removeEntry:candy];
}

- (void)notifier:(EntryNotifier *)notifier didUpdateEntry:(Candy *)candy event:(enum EntryUpdateEvent)event {
    [self sort:candy];
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return self.wrap == entry.container;
}

- (NSInteger)broadcasterOrderPriority:(WLBroadcaster *)broadcaster {
    return WLBroadcastReceiverOrderPriorityPrimary;
}

@end
