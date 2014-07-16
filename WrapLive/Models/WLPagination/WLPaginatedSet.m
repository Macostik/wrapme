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
    }
    return self;
}

- (void)resetEntries:(NSOrderedSet *)entries {
    [self.entries removeAllObjects];
    [self.entries unionOrderedSet:entries];
    [self.entries sortEntries];
}

- (id)send:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    self.request.newer = [[self.entries firstObject] updatedAt];
    self.request.older = [[self.entries lastObject] updatedAt];
    return [self.request send:^(NSOrderedSet *orderedSet) {
        if (orderedSet.nonempty) {
            [weakSelf.entries unionOrderedSet:orderedSet];
            [weakSelf.entries sortEntries];
        } else if (weakSelf.request.type != WLPaginatedRequestTypeNewer) {
            weakSelf.completed = YES;
        }
        if(success) {
            success(orderedSet);
        }
    } failure:failure];
}

@end
