//
//  WLSegmentedDataSource.h
//  moji
//
//  Created by Ravenpod on 1/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBasicDataSource.h"

@interface WLSegmentedDataSource : WLBasicDataSource

@property (strong, nonatomic) IBOutletCollection(WLDataSource) NSMutableArray *items;

@property (strong, nonatomic) IBInspectable NSString *nameFirstSegmentPlaceholder;
@property (strong, nonatomic) IBInspectable NSString *nameSecondSegmentPlaceholder;

@property (strong, nonatomic) WLDataSource* currentDataSource;

- (void)addDataSource:(WLDataSource*)dataSource;

- (void)removeDataSource:(WLDataSource*)dataSource;

- (void)setCurrentDataSourceAtIndex:(NSUInteger)index;

- (NSUInteger)indexOfCurrentDataSource;

@end
