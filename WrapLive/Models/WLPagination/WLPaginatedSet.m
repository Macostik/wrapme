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

+ (instancetype)setWithEntries:(NSOrderedSet *)entries {
    WLPaginatedSet* set = [[WLPaginatedSet alloc] init];
    [set resetEntries:entries];
    return set;
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
}

- (void)newer:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLEntry* entry = [self.entries firstObject];
    __weak typeof(self)weakSelf = self;
    [entry newer:self.sameDay success:^(NSOrderedSet *orderedSet) {
        if (orderedSet.nonempty) {
            [weakSelf.entries unionOrderedSet:orderedSet];
            [weakSelf.entries sortEntries];
        }
        if(success) {
            success(orderedSet);
        }
    } failure:failure];
}

- (void)older:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLEntry* entry = [self.entries lastObject];
    __weak typeof(self)weakSelf = self;
    [entry older:self.sameDay success:^(NSOrderedSet *orderedSet) {
        if (orderedSet.nonempty) {
            [weakSelf.entries unionOrderedSet:orderedSet];
            [weakSelf.entries sortEntries];
        } else {
            weakSelf.completed = YES;
        }
        if(success) {
            success(orderedSet);
        }
    } failure:failure];
}

@end
