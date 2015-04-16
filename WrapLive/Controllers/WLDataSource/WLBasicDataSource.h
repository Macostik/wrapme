//
//  WLBasicDataSource.h
//  WrapLive
//
//  Created by Sergey Maximenko on 1/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDataSource.h"

@interface WLBasicDataSource : WLDataSource

@property (strong, nonatomic) id <WLDataSourceItems> items;

@property (nonatomic, readonly) BOOL appendable;

@property (strong, nonatomic) void (^changeBlock) (id <WLDataSourceItems> items);

- (void)append:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end
