//
//  WLComposedDataSource.h
//  meWrap
//
//  Created by Ravenpod on 1/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSectionedDataSource.h"

@interface WLComposedDataSource : WLSectionedDataSource

@property (strong, nonatomic) IBOutletCollection(WLDataSource) NSMutableArray *items;

- (void)addDataSource:(WLDataSource*)dataSource;

- (void)removeDataSource:(WLDataSource*)dataSource;

@end
