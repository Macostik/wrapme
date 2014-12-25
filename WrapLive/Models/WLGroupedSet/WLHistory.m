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
        WLGroup* group = [self groupForDate:date create:YES];
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
    }
    if (added) {
        [self.entries sort:self.sortComparator];
    }
    return added;
}

- (BOOL)addEntry:(WLCandy*)candy {
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

@end

@implementation WLGroup

+ (instancetype)group {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sortComparator = comparatorByCreatedAt;
        self.offset = CGPointZero;
        self.request = [WLCandiesRequest request];
        self.request.sameDay = YES;
    }
    return self;
}

- (void)configureRequest:(WLCandiesRequest *)request {
    WLWrap* wrap = [[self.entries firstObject] wrap];
    if (wrap) {
        request.wrap = wrap;
    }
    [super configureRequest:request];
}

- (NSDate *)paginationDate {
    return self.date;
}

@end
