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
#import "WLOperationQueue.h"

@interface WLPaginatedSet ()

@end

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
        self.sortDescending = YES;
    }
    return self;
}

- (void)resetEntries:(NSOrderedSet *)entries {
    [self.entries removeAllObjects];
    [self.entries unionOrderedSet:entries];
    [self sort];
}

- (void)fresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    [self send:WLPaginatedRequestTypeFresh success:success failure:failure];
}

- (void)newer:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    [self send:WLPaginatedRequestTypeNewer success:success failure:failure];
}

- (void)older:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    [self send:WLPaginatedRequestTypeOlder success:success failure:failure];
}

- (void)recursiveOlder:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    [self older:^(NSOrderedSet *orderedSet) {
        if (success) success(orderedSet);
        if (!self.completed) {
            [self recursiveOlder:success failure:failure];
        }
    } failure:failure];
}

- (id)send:(WLPaginatedRequestType)type success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLPaginatedRequest* request = self.request;
    if (request) {
        __weak typeof(self)weakSelf = self;
        runUnaryQueuedOperation(@"wl_fetching_data_queue",^(WLOperation *operation) {
            if (weakSelf) {
                weakSelf.request.type = type;
                [weakSelf configureRequest:request];
                [request send:^(NSOrderedSet *orderedSet) {
                    [weakSelf handleResponse:orderedSet];
                    [operation finish];
                    if (success) success(orderedSet);
                } failure:^(NSError *error) {
                    [operation finish];
                    if (failure) failure(error);
                }];
            } else {
                [operation finish];
                if (success) success(nil);
            }
        });
    } else if (failure) {
        failure(nil);
    }
    return nil;
}

- (void)configureRequest:(WLPaginatedRequest *)request {
    if (!self.entries.nonempty) {
        request.type = WLPaginatedRequestTypeFresh;
    } else {
        request.newer = [self newerPaginationDate];
        request.older = [self olderPaginationDate];
    }
}

- (NSDate *)newerPaginationDate {
    WLEntry* firstEntry = [self.entries firstObject];
    return firstEntry.paginationDate;
}

- (NSDate *)olderPaginationDate {
    WLEntry* lastEntry = [self.entries lastObject];
    return lastEntry.paginationDate;
}

- (void)handleResponse:(NSOrderedSet*)entries {
    if ((!entries.nonempty || ![self addEntries:entries]) && self.request.type == WLPaginatedRequestTypeOlder) {
        self.completed = YES;
    } else if (!self.entries.nonempty) {
        self.completed = YES;
    } else {
        [self sort];
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
    [self.entries addObject:entry comparator:self.sortComparator descending:self.sortDescending];
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
    [self.entries sort:self.sortComparator descending:self.sortDescending];
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
