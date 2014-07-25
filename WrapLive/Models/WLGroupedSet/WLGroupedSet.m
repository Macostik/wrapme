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

@interface WLGroupedSet ()

@property (strong, nonatomic) NSMutableDictionary *keyedGroups;

@end

@implementation WLGroupedSet

+ (instancetype)groupsOrderedBy:(NSString *)orderBy {
    WLGroupedSet* groups = [[WLGroupedSet alloc] init];
    if ([orderBy isEqualToString:WLCandiesOrderByCreation]) {
        groups.groupSortComparator = comparatorByCreatedAtDescending;
        groups.dateBlock = ^NSDate* (WLEntry* entry) {
            return [entry createdAt];
        };
        groups.orderBy = WLCandiesOrderByCreation;
    }
    return groups;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.set = [NSMutableOrderedSet orderedSet];
        self.keyedGroups = [NSMutableDictionary dictionary];
        self.dateFormat = @"MMM dd, yyyy";
        self.singleMessage = YES;
        self.sortComparator = comparatorByDateDescending;
        self.groupSortComparator = comparatorByUpdatedAtDescending;
        self.dateBlock = ^NSDate* (WLEntry* entry) {
            return [entry updatedAt];
        };
        self.orderBy = WLCandiesOrderByUpdating;
    }
    return self;
}

- (void)setCandies:(NSOrderedSet *)candies {
    [self clear];
    [self addCandies:candies];
}

- (WLGroup *)group:(NSDate *)date {
    return [self group:date created:NULL];
}

- (WLGroup *)group:(NSDate *)date created:(BOOL *)created {
    if (self.skipToday && [date isToday]) {
        return nil;
    }
    NSString* name = [date stringWithFormat:self.dateFormat];
    WLGroup* group = [self.keyedGroups objectForKey:name];
    if (!group) {
        group = [WLGroup groupOrderedBy:self.orderBy];
        group.sortComparator = self.groupSortComparator;
        group.dateBlock = self.dateBlock;
        group.date = date;
        group.singleMessage = self.singleMessage;
        group.name = name;
        [self.keyedGroups setObject:group forKey:name];
        [self.set addObject:group];
        [self.set sort:self.sortComparator];
        if (created != NULL) {
            *created = YES;
        }
    }
    return group;
}

- (void)addCandies:(NSOrderedSet *)candies {
    BOOL created = NO;
    for (WLCandy* candy in candies) {
        if (self.dateBlock(candy)) {
            [self addCandy:candy created:&created];
        }
    }
    if (created) {
        [self.delegate groupedSetGroupsChanged:self];
    }
}

- (void)addCandy:(WLCandy *)candy {
    BOOL created = NO;
    [self addCandy:candy created:&created];
    if (created) {
        [self.delegate groupedSetGroupsChanged:self];
    }
}

- (void)addCandy:(WLCandy *)candy created:(BOOL *)created {
    NSDate* date = self.dateBlock(candy);
    if (date) {
        WLGroup* group = [self group:date created:created];
        [group addEntry:candy];
    }
}

- (void)removeCandy:(WLCandy *)candy {
    __block BOOL removed = NO;
    __weak typeof(self)weakSelf = self;
    [self.set removeObjectsWhileEnumerating:^BOOL(WLGroup* group) {
        if ([group.entries containsObject:candy]) {
            [group.entries removeObject:candy];
            removed = YES;
            if (group.entries.nonempty) {
                return NO;
            }
            [weakSelf.keyedGroups removeObjectForKey:group.name];
            return YES;
        }
        return NO;
    }];
    if (removed) {
        [self.delegate groupedSetGroupsChanged:self];
    }
}

- (void)clear {
    [self.set removeAllObjects];
    [self.keyedGroups removeAllObjects];
}

- (void)sort:(WLCandy*)candy {
    BOOL created = NO;
    WLGroup* group = [self group:self.dateBlock(candy) created:&created];
    if (!created && [group.entries containsObject:candy]) {
        [group sort];
        return;
    }
    __weak typeof(self)weakSelf = self;
    [self.set removeObjectsWhileEnumerating:^BOOL(WLGroup* group) {
        if ([group.entries containsObject:candy]) {
            [group.entries removeObject:candy];
            if (group.entries.nonempty) {
                return NO;
            }
            [weakSelf.keyedGroups removeObjectForKey:group.name];
            return YES;
        }
        return NO;
    }];
    [group addEntry:candy];
    [group sort];
    [self.delegate groupedSetGroupsChanged:self];
}

- (void)sort {
    for (WLGroup* group in self.set) {
        [group sort];
    }
}

- (WLGroup *)groupWithCandy:(WLCandy *)candy {
    return [self.set selectObject:^BOOL(WLGroup* item) {
        return [item.entries containsObject:candy];
    }];
}

- (WLGroup *)groupForDate:(NSDate *)date {
    return [self.set selectObject:^BOOL(WLGroup* item) {
        return [item.date isSameDay:date];
    }];
}

@end

@implementation WLGroup

+ (instancetype)group {
    return [[self alloc] init];
}

+ (instancetype)groupOrderedBy:(NSString *)orderBy {
    WLGroup* group = [self group];
    group.request.orderBy = orderBy;
    return group;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.offset = CGPointZero;
        self.request = [WLCandiesRequest request];
        self.request.sameDay = YES;
    }
    return self;
}

- (id)send:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLCandiesRequest* request = (id)self.request;
    request.wrap = [[self.entries firstObject] wrap];
    return [super send:success failure:failure];
}

- (BOOL)shouldAddEntry:(WLCandy*)entry {
    if (self.singleMessage && [entry isMessage]) {
        if (!self.message) {
            self.message = entry;
            return YES;
        } else if ([self.dateBlock(self.message) compare:self.dateBlock(entry)] == NSOrderedAscending) {
            [self.entries removeObject:self.message];
            self.message = entry;
            return YES;
        }
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)hasAtLeastOneImage {
    for (WLCandy* candy in self.entries) {
        if ([candy isImage]) {
            return YES;
        }
    }
    return NO;
}

@end
