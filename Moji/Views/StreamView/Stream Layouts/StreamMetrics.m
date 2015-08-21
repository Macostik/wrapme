//
//  StreamMetrics.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamMetrics.h"
#import "StreamView.h"

@interface StreamMetrics ()

@property (strong, nonatomic) StreamMetricsViewWillAppearBlock viewWillAppearBlock;

@end

@implementation StreamMetrics

+ (instancetype)metrics:(StreamMetricsBlock)block {
    return [[[self alloc] init] change:block];
}

- (instancetype)change:(StreamMetricsBlock)block {
    if (block) block(self);
    return self;
}

- (BOOL)hiddenAt:(StreamIndex *)index {
    return self.hiddenBlock ? self.hiddenBlock(index) : self.hidden;
}

- (CGFloat)sizeAt:(StreamIndex *)index {
    return self.sizeBlock ? self.sizeBlock(index) : self.size;
}

- (CGRect)insetsAt:(StreamIndex *)index {
    return self.insetsBlock ? self.insetsBlock(index) : self.insets;
}

- (id)viewForItem:(StreamItem *)item inStreamView:(StreamView *)streamView entry:(id)entry {
    StreamReusableView *view = [streamView viewForItem:item];
    view.entry = entry;
    if (self.viewWillAppearBlock) self.viewWillAppearBlock(item, view, entry);
    return view;
}

@end
