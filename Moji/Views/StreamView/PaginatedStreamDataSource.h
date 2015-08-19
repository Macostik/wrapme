//
//  PaginatedStreamDataSource.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamDataSource.h"
#import "WLPaginatedSet+WLBaseOrderedCollection.h"

@interface PaginatedStreamDataSource : StreamDataSource

@property (nonatomic) IBInspectable BOOL headerAnimated;

@property (strong, nonatomic) WLPaginatedSet *items;

@property (strong, nonatomic) BOOL (^appendableBlock) (PaginatedStreamDataSource *dataSource);

- (void)append:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end
