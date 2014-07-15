//
//  WLPagination.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLBlocks.h"

@interface WLPaginatedSet : NSObject

@property (strong, nonatomic) NSMutableOrderedSet* entries;

@property (nonatomic) BOOL sameDay;

@property (nonatomic) BOOL completed;

@property (strong, nonatomic) id relatedEntry;

@property (strong, nonatomic) Class entryClass;

+ (instancetype)setWithEntries:(NSOrderedSet*)entries entryClass:(Class)entryClass;

+ (instancetype)setWithEntries:(NSOrderedSet*)entries entryClass:(Class)entryClass relatedEntry:(id)relatedEntry;

+ (instancetype)setWithEntryClass:(Class)entryClass;

+ (instancetype)setWithEntryClass:(Class)entryClass relatedEntry:(id)relatedEntry;

- (void)resetEntries:(NSOrderedSet*)entries;

- (id)older:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (id)newer:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (id)fresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

@end
