//
//  StreamViewDataSource.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamViewDataSource.h"

@implementation StreamViewDataSource

- (void)setItems:(id<WLBaseOrderedCollection>)items {
    _items = items;
    [self reload];
}

- (void)reload {
    [self.streamView reload];
}

- (void)setItemIdentifier:(NSString *)itemIdentifier {
    if (!self.metrics) self.metrics = [[StreamMetrics alloc] init];
    self.metrics.identifier = itemIdentifier;
}

- (NSString *)itemIdentifier {
    return self.metrics.identifier;
}

- (void)setItemSize:(CGFloat)itemSize {
    if (!self.metrics) self.metrics = [[StreamMetrics alloc] init];
    self.metrics.size.value = itemSize;
}

- (CGFloat)itemSize {
    return self.metrics.size.value;
}

// MARK: - StreamViewDelegate

- (NSInteger)streamView:(StreamView*)streamView numberOfItemsInSection:(NSInteger)section {
    return [self.items count];
}

- (id)streamView:(StreamView*)streamView viewForItem:(StreamItem*)item {
    StreamReusableView *view = [streamView viewForItem:item];
    view.entry = [self.items tryAt:item.index.next.value];
    return view;
}

- (StreamMetrics*)streamView:(StreamView*)streamView metricsAt:(StreamIndex*)index {
    return self.metrics;
}

- (NSInteger)streamViewNumberOfSections:(StreamView*)streamView {
    return 1;
}

- (void)streamView:(StreamView*)streamView didSelectItem:(StreamItem*)item {
    
}

@end
