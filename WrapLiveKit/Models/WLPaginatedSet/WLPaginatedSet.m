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
#import "WLEntryNotifier.h"

@interface WLPaginatedSet ()

@end

@implementation WLPaginatedSet

+ (instancetype)setWithEntries:(NSSet *)entries request:(WLPaginatedRequest *)request {
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

- (void)resetEntries:(NSSet *)entries {
    [self.entries removeAllObjects];
    [self.entries unionSet:entries];
    [self sort];
}

- (void)fresh:(WLSetBlock)success failure:(WLFailureBlock)failure {
    [self send:WLPaginatedRequestTypeFresh success:success failure:failure];
}

- (void)newer:(WLSetBlock)success failure:(WLFailureBlock)failure {
    [self send:WLPaginatedRequestTypeNewer success:success failure:failure];
}

- (void)older:(WLSetBlock)success failure:(WLFailureBlock)failure {
    [self send:WLPaginatedRequestTypeOlder success:success failure:failure];
}

- (void)recursiveOlder:(WLFailureBlock)failure {
    [self older:^(NSSet *set) {
        if (!self.completed) {
            [self recursiveOlder:failure];
        }
    } failure:failure];
}

- (id)send:(WLPaginatedRequestType)type success:(WLSetBlock)success failure:(WLFailureBlock)failure {
    WLPaginatedRequest* request = self.request;
    if (request) {
        __weak typeof(self)weakSelf = self;
        runUnaryQueuedOperation(WLOperationFetchingDataQueue,^(WLOperation *operation) {
            if (weakSelf && request) {
                weakSelf.request.type = type;
                [weakSelf configureRequest:request];
                [request send:^(NSSet *set) {
                    [weakSelf handleResponse:set];
                    [operation finish];
                    if (success) success(set);
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

- (void)handleResponse:(NSSet*)entries {
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
        if (completed) {
            [self didBecomeCompleted];
        } else {
            [self didChange];
        }
    }

}

- (BOOL)addEntries:(NSSet *)entries {
    if (!entries.nonempty || [entries isSubsetOfSet:self.entries.set]) {
        return NO;
    }
    [self.entries unionSet:entries];
    [self sort];
    return YES;
}

- (BOOL)addEntry:(id)entry {
    if ([self.entries containsObject:entry]) {
        return NO;
    }
    [self.entries add:entry comparator:self.sortComparator descending:self.sortDescending];
    [self didChange];
    return YES;
}

- (void)removeEntry:(id)entry {
    if ([self.entries containsObject:entry]) {
        [self.entries removeObject:entry];
        [self didChange];
    }
}

- (void)sort {
    [self.entries sort:self.sortComparator descending:self.sortDescending];
    [self didChange];
}

- (void)sort:(id)entry {
    [self sort];
}

- (void)didChange {
    [self.delegate paginatedSetChanged:self];
}

- (void)didBecomeCompleted {
    [self.delegate paginatedSetCompleted:self];
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
