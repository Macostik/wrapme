//
//  WLGroupedSet.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLGroupedSet.h"
#import "WLCandy+Extended.h"
#import "WLEntry+Extended.h"
#import "NSDate+Formatting.h"
#import "NSOrderedSet+Additions.h"
#import "NSDate+Additions.h"
#import "WLWrapRequest.h"

@interface WLGroupedSet ()

@end

@implementation WLGroupedSet

- (instancetype)init {
    self = [super init];
    if (self) {
//        self.dateFormat = @"MMM dd, yyyy";
        self.type = @(WLCandyTypeImage);
        self.sortComparator = comparatorByDateDescending;
    }
    return self;
}

- (void)resetEntries:(NSOrderedSet *)entries {
    [self clear];
    [self addEntries:entries];
}

- (BOOL)addEntries:(NSOrderedSet *)entries {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"type == %@", self.type];
    entries = [entries filteredOrderedSetUsingPredicate:predicate];
    BOOL added = NO;
    NSMutableOrderedSet* _entries = [entries mutableCopy];
    while (_entries.nonempty) {
        WLCandy* candy = [_entries firstObject];
        NSDate* date = candy.createdAt;
        WLGroup* group = [self groupForDate:date create:YES];
        predicate = [NSPredicate predicateWithFormat:@"createdAt >= %@ AND createdAt <= %@", [date beginOfDay], [date endOfDay]];
        NSOrderedSet* dayEntries = [_entries filteredOrderedSetUsingPredicate:predicate];
        if ([group addEntries:dayEntries]) {
            added = YES;
        }
        [_entries minusOrderedSet:dayEntries];
    }
    if (added) {
        [self.entries sort:self.sortComparator];
    }
    return added;
}

- (BOOL)addEntry:(WLCandy*)candy {
    if (![candy.type isEqualToNumber:self.type]) {
        return NO;
    }
    WLGroup* group = [self groupForDate:candy.createdAt create:YES];
    if ([group addEntry:candy]) {
        [self.entries sort:self.sortComparator];
        return YES;
    }
    return NO;
}

- (void)removeEntry:(id)entry {
    __block BOOL removed = NO;
    [self.entries removeObjectsWhileEnumerating:^BOOL(WLGroup* group) {
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
    if (![candy.type isEqualToNumber:self.type]) {
        return;
    }
    WLGroup* group = [self groupForDate:candy.createdAt create:YES];
    if ([group.entries containsObject:candy]) {
        [group sort];
        return;
    }
    [self.entries removeObjectsWhileEnumerating:^BOOL(WLGroup* group) {
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
    for (WLGroup* group in self.entries) {
        [group sort];
    }
}

- (WLGroup *)groupWithCandy:(WLCandy *)candy {
    return [self.entries selectObject:^BOOL(WLGroup* item) {
        return [item.entries containsObject:candy];
    }];
}

- (WLGroup *)groupForDate:(NSDate *)date {
    return [self.entries selectObject:^BOOL(WLGroup* item) {
        return [item.date isSameDay:date];
    }];
}

- (WLGroup *)groupForDate:(NSDate *)date create:(BOOL)create {
    WLGroup* group = [self.entries selectObject:^BOOL(WLGroup* item) {
        return [item.date isSameDay:date];
    }];
    if (!group && create) {
        group = [WLGroup group];
        group.date = date;
        [self.entries addObject:group];
        [self.delegate paginatedSetChanged:self];
    }
    return group;
}

- (id)send:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    if (self.request.type == WLPaginatedRequestTypeOlder) {
        WLWrapRequest* request = (id)self.request;
        request.page = ((self.entries.count + 1)/10 + 1);
    }
    return [super send:success failure:failure];
}

@end

@implementation WLGroup

+ (instancetype)group {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sortComparator = comparatorByCreatedAtDescending;
        self.offset = CGPointZero;
        self.request = [WLCandiesRequest request];
        self.request.sameDay = YES;
    }
    return self;
}

- (id)send:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLCandiesRequest* request = (id)self.request;
    WLWrap* wrap = [[self.entries firstObject] wrap];
    if (wrap) {
        request.wrap = wrap;
    }
    return [super send:success failure:failure];
}

- (NSDate*)updatedAt {
    return self.date;
}

@end
