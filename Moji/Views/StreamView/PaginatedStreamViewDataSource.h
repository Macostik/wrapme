//
//  PaginatedStreamViewDataSource.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamViewDataSource.h"
#import "WLPaginatedSet+WLBaseOrderedCollection.h"

@interface PaginatedStreamViewDataSource : StreamViewDataSource

@property (strong, nonatomic) WLPaginatedSet *items;

@property (strong, nonatomic) BOOL (^appendableBlock) (PaginatedStreamViewDataSource *dataSource);

- (void)refresh;

- (void)refresh:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)append:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end
