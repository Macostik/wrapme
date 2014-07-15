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

+ (instancetype)setWithEntries:(NSOrderedSet*)entries;

- (void)resetEntries:(NSOrderedSet*)entries;

- (void)older:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (void)newer:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

@end
