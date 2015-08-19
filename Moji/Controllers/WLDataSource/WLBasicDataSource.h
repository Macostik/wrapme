//
//  WLBasicDataSource.h
//  moji
//
//  Created by Ravenpod on 1/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDataSource.h"

@interface WLBasicDataSource : WLDataSource

@property (strong, nonatomic) id <WLBaseOrderedCollection> items;

@property (nonatomic) IBInspectable BOOL headerAnimated;

@property (nonatomic, readonly) BOOL appendable;

@property (strong, nonatomic) BOOL (^appendableBlock) (id <WLBaseOrderedCollection> items);

- (void)append:(WLObjectBlock)success failure:(WLFailureBlock)failure;

@end
