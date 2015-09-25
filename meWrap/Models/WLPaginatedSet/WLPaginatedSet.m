//
//  WLPagination.m
//  meWrap
//
//  Created by Ravenpod on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet.h"
#import "WLEntryManager.h"
#import "WLEntry+WLAPIRequest.h"
#import "WLOperationQueue.h"
#import "WLEntryNotifier.h"

@interface WLPaginatedSet ()

@property (nonatomic) NSMutableIndexSet *loadingTypes;

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

- (NSMutableIndexSet *)loadingTypes {
    if (!_loadingTypes) {
        _loadingTypes = [NSMutableIndexSet indexSet];
    }
    return _loadingTypes;
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

- (id)send:(WLPaginatedRequestType)type success:(WLSetBlock)success failure:(WLFailureBlock)failure {
    WLPaginatedRequest* request = self.request;
    if (request) {
        if ([self.loadingTypes containsIndex:type]) {
            if (failure) failure(nil);
            return nil;
        }
        [self.loadingTypes addIndex:type];
        __weak typeof(self)weakSelf = self;
        runUnaryQueuedOperation(WLOperationFetchingDataQueue,^(WLOperation *operation) {
            if (weakSelf && request) {
                weakSelf.request.type = type;
                [weakSelf configureRequest:request];
                [request send:^(NSSet *set) {
                    [weakSelf.loadingTypes removeIndex:type];
                    [weakSelf handleResponse:set];
                    [operation finish];
                    if (success) success(set);
                } failure:^(NSError *error) {
                    [weakSelf.loadingTypes removeIndex:type];
                    [operation finish];
                    if (failure) failure(error);
                }];
            } else {
                [weakSelf.loadingTypes removeIndex:type];
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
    }
}

- (void)setCompleted:(BOOL)completed {
    if (completed != _completed) {
        _completed = completed;
        [self didChange];
    }
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
