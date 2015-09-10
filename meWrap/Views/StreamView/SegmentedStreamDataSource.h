//
//  SegmentedStreamViewDataSource.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamDataSource.h"

@interface SegmentedStreamDataSource : StreamDataSource

@property (strong, nonatomic) IBOutletCollection(StreamDataSource) NSMutableArray *items;

@property (strong, nonatomic) StreamDataSource* currentDataSource;

@end
