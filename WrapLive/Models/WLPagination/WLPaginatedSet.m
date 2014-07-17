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
        self.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]];
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
            NSUInteger count = [weakSelf.entries count];
            [weakSelf addEntries:orderedSet];
            if (weakSelf.request.type != WLPaginatedRequestTypeNewer && count != [weakSelf.entries count]) {
                weakSelf.completed = YES;
            }
        } else if (weakSelf.request.type != WLPaginatedRequestTypeNewer) {
            weakSelf.completed = YES;
        }
        if(success) {
            success(orderedSet);
        }
    } failure:failure];
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

- (void)sort {
    [self.entries sortUsingDescriptors:self.sortDescriptors];
    [self.delegate paginatedSetChanged:self];
}

@end
