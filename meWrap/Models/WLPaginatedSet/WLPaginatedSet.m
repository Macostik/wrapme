//
//  WLPagination.m
//  meWrap
//
//  Created by Ravenpod on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet.h"
#import "WLOperationQueue.h"

@interface WLPaginatedSet ()

@end

@implementation WLPaginatedSet

@dynamic delegate;

+ (instancetype)setWithEntries:(NSSet *)entries request:(PaginatedRequest *)request {
    WLPaginatedSet* set = [[WLPaginatedSet alloc] init];
    set.request = request;
    [set resetEntries:entries];
    return set;
}

+ (instancetype)setWithRequest:(PaginatedRequest *)request {
    return [self setWithEntries:nil request:request];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.paginationDateKeyPath = @"updatedAt";
    }
    return self;
}

- (NSMutableIndexSet *)loadingTypes {
    if (!_loadingTypes) {
        _loadingTypes = [NSMutableIndexSet indexSet];
    }
    return _loadingTypes;
}

- (void)addLoadingType:(NSUInteger)type {
    [self.loadingTypes addIndex:type];
    if (self.loadingTypes.count == 1) {
        if ([self.delegate respondsToSelector:@selector(paginatedSetDidStartLoading:)]) {
            [self.delegate paginatedSetDidStartLoading:self];
        }
    }
}

- (void)removeLoadingType:(NSUInteger)type {
    [self.loadingTypes removeIndex:type];
    if (self.loadingTypes.count == 0) {
        if ([self.delegate respondsToSelector:@selector(paginatedSetDidFinishLoading:)]) {
            [self.delegate paginatedSetDidFinishLoading:self];
        }
    }
}

- (void)fresh:(ArrayBlock)success failure:(FailureBlock)failure {
    [self send:PaginatedRequestTypeFresh success:success failure:failure];
}

- (void)newer:(ArrayBlock)success failure:(FailureBlock)failure {
    [self send:PaginatedRequestTypeNewer success:success failure:failure];
}

- (void)older:(ArrayBlock)success failure:(FailureBlock)failure {
    [self send:PaginatedRequestTypeOlder success:success failure:failure];
}

- (id)send:(PaginatedRequestType)type success:(ArrayBlock)success failure:(FailureBlock)failure {
    PaginatedRequest* request = self.request;
    if (request) {
        if ([self.loadingTypes containsIndex:type]) {
            if (failure) failure(nil);
            return nil;
        }
        [self addLoadingType:type];
        __weak typeof(self)weakSelf = self;
        runUnaryQueuedOperation(WLOperationFetchingDataQueue,^(WLOperation *operation) {
            if (weakSelf && request) {
                weakSelf.request.type = type;
                [weakSelf configureRequest:request];
                [request send:^(NSArray *array) {
                    [weakSelf handleResponse:array];
                    [weakSelf removeLoadingType:type];
                    [operation finish];
                    if (success) success(array);
                } failure:^(NSError *error) {
                    [weakSelf removeLoadingType:type];
                    [operation finish];
                    if (failure) failure(error);
                }];
            } else {
                [weakSelf removeLoadingType:type];
                [operation finish];
                if (success) success(nil);
            }
        });
    } else if (failure) {
        failure(nil);
    }
    return nil;
}

- (void)configureRequest:(PaginatedRequest *)request {
    if (!self.entries.nonempty) {
        request.type = PaginatedRequestTypeFresh;
    } else {
        request.newer = [self newerPaginationDate];
        request.older = [self olderPaginationDate];
    }
}

- (NSDate *)newerPaginationDate {
    Entry *firstEntry = [self.entries firstObject];
    return [firstEntry valueForKeyPath:self.paginationDateKeyPath];
}

- (NSDate *)olderPaginationDate {
    Entry *lastEntry = [self.entries lastObject];
    return [lastEntry valueForKeyPath:self.paginationDateKeyPath];
}

- (void)handleResponse:(NSArray*)entries {
    if ((!entries.nonempty || ![self addEntries:[entries set]]) && self.request.type == PaginatedRequestTypeOlder) {
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
