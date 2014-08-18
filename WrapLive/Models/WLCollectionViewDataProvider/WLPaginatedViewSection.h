//
//  WLPaginatedViewSection.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCollectionViewSection.h"
#import "WLPaginatedSet.h"

@interface WLPaginatedViewSection : WLCollectionViewSection

@property (strong, nonatomic) WLPaginatedSet* entries;

@property (nonatomic) BOOL completed;

- (void)append:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (void)refresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (void)append;

- (void)refresh;

@end
