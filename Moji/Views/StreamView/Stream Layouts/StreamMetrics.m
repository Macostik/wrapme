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

@implementation StreamMetricsProperty

- (id)valueAt:(StreamIndex*)index {
    return self.block ? self.block(index) : self.value;
}

@end

@interface StreamMetrics ()

@property (strong, nonatomic) StreamMetricsViewBeforeSetupBlock viewBeforeSetupBlock;

@property (strong, nonatomic) StreamMetricsViewAfterSetupBlock viewAfterSetupBlock;

@end

@implementation StreamMetrics

+ (instancetype)metrics:(StreamMetricsBlock)block {
    return [[[self alloc] init] change:block];
}

- (instancetype)change:(StreamMetricsBlock)block {
    if (block) block(self);
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.size = [[StreamMetricsFloatProperty alloc] init];
        self.topInset = [[StreamMetricsFloatProperty alloc] init];
        self.bottomInset = [[StreamMetricsFloatProperty alloc] init];
        self.leftInset = [[StreamMetricsFloatProperty alloc] init];
        self.rightInset = [[StreamMetricsFloatProperty alloc] init];
        self.hidden = [[StreamMetricsBoolProperty alloc] init];
    }
    return self;
}

- (id)viewForItem:(StreamItem *)item inStreamView:(StreamView *)streamView entry:(id)entry {
    StreamReusableView *view = [streamView viewForItem:item];
    if (self.viewBeforeSetupBlock) self.viewBeforeSetupBlock(item, view, entry);
    view.entry = entry;
    if (self.viewAfterSetupBlock) self.viewAfterSetupBlock(item, view, entry);
    return view;
}

@end
