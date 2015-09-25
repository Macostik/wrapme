//
//  PaginatedStreamDataSource.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamDataSource.h"
#import "WLPaginatedSet.h"

@interface PaginatedStreamDataSource : StreamDataSource

@property (strong, nonatomic) WLPaginatedSet *items;

@property (strong, nonatomic) BOOL (^appendableBlock) (PaginatedStreamDataSource *dataSource);

@property (weak, nonatomic) StreamMetrics *loadingMetrics;

- (void)append:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end
