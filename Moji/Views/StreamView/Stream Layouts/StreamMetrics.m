//
//  StreamMetrics.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamMetrics.h"

@implementation StreamMetricsFloatProperty

- (CGFloat)valueAt:(StreamIndex *)index {
    return self.block ? self.block(index) : self.value;
}

@end

@implementation StreamMetricsBoolProperty

- (BOOL)valueAt:(StreamIndex*)index {
    return self.block ? self.block(index) : self.value;
}

@end

@implementation StreamMetricsStringProperty

- (NSString*)valueAt:(StreamIndex*)index {
    return self.block ? self.block(index) : self.value;
}

@end

@implementation StreamMetrics

+ (instancetype)metrics:(StreamMetricsBlock)block {
    StreamMetrics *metrics = [[self alloc] init];
    if (block) block(metrics);
    return metrics;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.headers = [NSMutableArray array];
        self.footers = [NSMutableArray array];
        self.size = [[StreamMetricsFloatProperty alloc] init];
        self.hidden = [[StreamMetricsBoolProperty alloc] init];
    }
    return self;
}

- (instancetype)addHeader:(StreamMetricsBlock)block {
    StreamMetrics *metrics = [[self class] metrics:block];
    [self.headers addObject:metrics];
    return metrics;
}

- (instancetype)addFooter:(StreamMetricsBlock)block {
    StreamMetrics *metrics = [[self class] metrics:block];
    [self.footers addObject:metrics];
    return metrics;
}

@end
