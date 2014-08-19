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

- (void)resetEntries:(NSOrderedSet *)entries {
    [self clear];
    [self addEntries:entries];
}

- (WLGroup *)group:(NSDate *)date {
    return [self group:date created:NULL];
}

- (WLGroup *)group:(NSDate *)date created:(BOOL *)created {
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
        [self.entries addObject:group];
        [self.entries sort:self.sortComparator];
        if (created != NULL) {
            *created = YES;
        }
    }
    return group;
}

- (BOOL)addEntries:(NSOrderedSet *)entries sort:(BOOL)sort {
    BOOL created = NO;
    BOOL added = NO;
    for (WLCandy* candy in entries) {
        if (self.dateBlock(candy)) {
            if ([self addEntry:candy created:&created]) {
                added = YES;
            }
        }
    }
    if (created) {
        [self.delegate paginatedSetChanged:self];
    }
    return added;
}

- (BOOL)addEntry:(id)entry {
    BOOL created = NO;
    BOOL added = [self addEntry:entry created:&created];
    if (created) {
        [self.delegate paginatedSetChanged:self];
    }
    return added;
}

- (BOOL)addEntry:(id)entry created:(BOOL *)created {
    NSDate* date = self.dateBlock(entry);
    if (date) {
        WLGroup* group = [self group:date created:created];
        if ([group addEntry:entry]) {
            return YES;
        }
    }
    return NO;
}

- (void)removeEntry:(id)entry {
    __block BOOL removed = NO;
    __weak typeof(self)weakSelf = self;
    [self.entries removeObjectsWhileEnumerating:^BOOL(WLGroup* group) {
        if ([group.entries containsObject:entry]) {
            [group.entries removeObject:entry];
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
        [self.delegate paginatedSetChanged:self];
    }
}

- (void)clear {
    [self.entries removeAllObjects];
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
    [self.entries removeObjectsWhileEnumerating:^BOOL(WLGroup* group) {
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
    WLWrap* wrap = [[self.entries firstObject] wrap];
    if (wrap) {
        request.wrap = wrap;
    }
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

- (NSDate*)updatedAt {
    return self.date;
}

@end
