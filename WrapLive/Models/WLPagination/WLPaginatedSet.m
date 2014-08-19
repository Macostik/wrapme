//
//  WLPagination.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet.h"
#import "WLEntryManager.h"
#import "WLAPIManager.h"

@implementation WLPaginatedSet

+ (instancetype)setWithEntries:(NSOrderedSet *)entries request:(WLPaginatedRequest *)request {
    WLPaginatedSet* set = [[WLPaginatedSet alloc] init];
    set.request = request;
    [set resetEntries:entries];
    return set;
}

+ (instancetype)setWithRequest:(WLPaginatedRequest *)request {
    return [self setWithEntries:nil request:request];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.entries = [NSMutableOrderedSet orderedSet];
        self.sortComparator = comparatorByUpdatedAtDescending;
    }
    return self;
}

- (void)resetEntries:(NSOrderedSet *)entries {
    [self.entries removeAllObjects];
    [self.entries unionOrderedSet:entries];
    [self.entries sortByUpdatedAtDescending];
    [self.delegate paginatedSetChanged:self];
}

- (id)fresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    self.request.type = WLPaginatedRequestTypeFresh;
    return [self send:success failure:failure];
}

- (id)newer:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    self.request.type = WLPaginatedRequestTypeNewer;
    return [self send:success failure:failure];
}

- (id)older:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    self.request.type = WLPaginatedRequestTypeOlder;
    return [self send:success failure:failure];
}

- (id)send:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    if (!self.entries.nonempty) {
        self.request.type = WLPaginatedRequestTypeFresh;
    } else {
        WLEntry* firstEntry = [self.entries firstObject];
        WLEntry* lastEntry = [self.entries firstObject];
        self.request.newer = [firstEntry updatedAt];
        self.request.older = [lastEntry updatedAt];
    }
    __weak typeof(self)weakSelf = self;
    return [self.request send:^(NSOrderedSet *orderedSet) {
        [weakSelf handleResponse:orderedSet success:success];
    } failure:failure];
}

- (void)handleResponse:(NSOrderedSet*)entries success:(WLOrderedSetBlock)success {
    if (!entries.nonempty || ![self addEntries:entries]) {
        self.completed = YES;
        [self.delegate paginatedSetChanged:self];
    }
    if(success) {
        success(entries);
    }
}

- (BOOL)addEntries:(NSOrderedSet *)entries sort:(BOOL)sort {
    BOOL added = NO;
    for (id entry in entries) {
        if ([self addEntry:entry sort:NO]) {
            added = YES;
        }
    }
    if (added) {
        if (sort) {
            [self sort];
        } else {
            [self.delegate paginatedSetChanged:self];
        }
    }
    return added;
}

- (BOOL)addEntries:(NSOrderedSet *)entries {
    return [self addEntries:entries sort:YES];
}

- (BOOL)addEntry:(id)entry {
    return [self addEntry:entry sort:YES];
}

- (BOOL)addEntry:(id)entry sort:(BOOL)sort {
    if ([self.entries containsObject:entry] || ![self shouldAddEntry:entry]) {
        return NO;
    }
    [self.entries addObject:entry];
    if (sort) {
        [self sort];
    }
    return YES;
}

- (BOOL)shouldAddEntry:(id)entry {
    return YES;
}

- (void)removeEntry:(id)entry {
    if ([self.entries containsObject:entry]) {
        [self.entries removeObject:entry];
        [self.delegate paginatedSetChanged:self];
    }
}

- (void)sort {
    [self.entries sort:self.sortComparator];
    [self.delegate paginatedSetChanged:self];
}

- (void)sort:(id)entry {
    [self sort];
}

@end
