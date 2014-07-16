//
//  WLPagination.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLBlocks.h"
#import "WLPaginatedRequest.h"

@interface WLPaginatedSet : NSObject

@property (strong, nonatomic) NSMutableOrderedSet* entries;

@property (nonatomic) BOOL completed;

@property (strong, nonatomic) WLPaginatedRequest* request;

+ (instancetype)setWithEntries:(NSOrderedSet*)entries request:(WLPaginatedRequest*)request;

+ (instancetype)setWithRequest:(WLPaginatedRequest*)request;

- (void)resetEntries:(NSOrderedSet*)entries;

- (id)send:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

@end
