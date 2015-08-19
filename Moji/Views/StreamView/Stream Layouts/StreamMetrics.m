//
//  StreamMetrics.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamMetrics.h"
#import "StreamView.h"

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

@interface StreamMetrics ()

@property (strong, nonatomic) StreamMetricsViewBeforeSetupBlock viewBeforeSetupBlock;

@property (strong, nonatomic) StreamMetricsViewAfterSetupBlock viewAfterSetupBlock;

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
        self.topSpacing = [[StreamMetricsFloatProperty alloc] init];
        self.bottomSpacing = [[StreamMetricsFloatProperty alloc] init];
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

- (id)viewForItem:(StreamItem *)item inStreamView:(StreamView *)streamView entry:(id)entry {
    StreamReusableView *view = [streamView viewForItem:item];
    if (self.viewBeforeSetupBlock) self.viewBeforeSetupBlock(item, view, entry);
    view.entry = entry;
    if (self.viewAfterSetupBlock) self.viewAfterSetupBlock(item, view, entry);
    return view;
}

@end
