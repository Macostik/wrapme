//
//  GridMetrics.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "GridMetrics.h"

@implementation GridMetrics

- (instancetype)init {
    self = [super init];
    if (self) {
        self.ratio = [[StreamMetricsFloatProperty alloc] init];
    }
    return self;
}

@end
