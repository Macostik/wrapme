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

+ (instancetype)setWithEntries:(NSOrderedSet *)entries entryClass:(__unsafe_unretained Class)entryClass relatedEntry:(id)relatedEntry {
    WLPaginatedSet* set = [[WLPaginatedSet alloc] init];
    set.entryClass = entryClass;
    set.relatedEntry = relatedEntry;
    [set resetEntries:entries];
    return set;
}

+ (instancetype)setWithEntries:(NSOrderedSet *)entries entryClass:(Class)entryClass {
    return [self setWithEntries:entries entryClass:entryClass relatedEntry:nil];
}

+ (instancetype)setWithEntryClass:(Class)entryClass {
    return [self setWithEntries:nil entryClass:entryClass relatedEntry:nil];
}

+ (instancetype)setWithEntryClass:(Class)entryClass relatedEntry:(id)relatedEntry {
    return [self setWithEntries:nil entryClass:entryClass relatedEntry:relatedEntry];
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

- (id)newer:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLEntry* entry = [self.entries firstObject];
    __weak typeof(self)weakSelf = self;
    return [entry newer:self.sameDay success:^(NSOrderedSet *orderedSet) {
        if (orderedSet.nonempty) {
            [weakSelf.entries unionOrderedSet:orderedSet];
            [weakSelf.entries sortEntries];
        }
        if(success) {
            success(orderedSet);
        }
    } failure:failure];
}

- (id)older:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLEntry* entry = [self.entries lastObject];
    __weak typeof(self)weakSelf = self;
    return [entry older:self.sameDay success:^(NSOrderedSet *orderedSet) {
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

- (id)fresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    return [self.entryClass fresh:self.relatedEntry success:^(NSOrderedSet *orderedSet) {
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
