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
        self.sortComparator = comparatorByUpdatedAt;
    }
    return self;
}

- (void)resetEntries:(NSOrderedSet *)entries {
    [self.entries removeAllObjects];
    [self.entries unionOrderedSet:entries];
    [self.entries sortByUpdatedAt];
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
    WLPaginatedRequest* request = self.request;
    if (request) {
        [self configureRequest:request];
        __weak typeof(self)weakSelf = self;
        return [request send:^(NSOrderedSet *orderedSet) {
            [weakSelf handleResponse:orderedSet success:success];
        } failure:failure];
    } else {
        if (failure) failure(nil);
        return nil;
    }
}

- (void)configureRequest:(WLPaginatedRequest *)request {
    if (!self.entries.nonempty) {
        request.type = WLPaginatedRequestTypeFresh;
    } else {
        WLEntry* firstEntry = [self.entries firstObject];
        WLEntry* lastEntry = [self.entries lastObject];
        request.newer = firstEntry.paginationDate;
        request.older = lastEntry.paginationDate;
    }
}

- (void)handleResponse:(NSOrderedSet*)entries success:(WLOrderedSetBlock)success {
    if ((!entries.nonempty || ![self addEntries:entries]) && self.request.type == WLPaginatedRequestTypeOlder) {
        self.completed = YES;
    } else if (!self.entries.nonempty) {
        self.completed = YES;
    } else {
        [self.delegate paginatedSetChanged:self];
    }
    
    if(success) {
        success(entries);
    }
}

- (void)setCompleted:(BOOL)completed {
    if (completed != _completed) {
        _completed = completed;
        [self.delegate paginatedSetChanged:self];
    }
}

- (BOOL)addEntries:(NSOrderedSet *)entries {
    if (!entries.nonempty || [entries isSubsetOfOrderedSet:self.entries]) {
        return NO;
    }
    [self.entries unionOrderedSet:entries];
    [self sort];
    return YES;
}

- (BOOL)addEntry:(id)entry {
    if ([self.entries containsObject:entry]) {
        return NO;
    }
    [self.entries addObject:entry comparator:self.sortComparator descending:YES];
    [self.delegate paginatedSetChanged:self];
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

@implementation WLEntry (WLPaginatedSet)

- (NSDate *)paginationDate {
    return self.updatedAt;
}

@end

@implementation WLCandy (WLPaginatedSet)

- (NSDate *)paginationDate {
    return self.createdAt;
}

@end
