//
//  SegmentedStreamViewDataSource.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "SegmentedStreamDataSource.h"
#import "SegmentedControl.h"

@interface SegmentedStreamDataSource () <SegmentedControlDelegate>

@end

@implementation SegmentedStreamDataSource

@dynamic items;

- (void)setStreamView:(StreamView *)streamView {
    [super setStreamView:streamView];
    if (streamView) {
        for (StreamDataSource *dataSource in self.items) {
            dataSource.streamView = streamView;
        }
    }
    self.currentDataSource = self.currentDataSource ? : [self.items firstObject];
}

- (void)setItems:(NSMutableArray *)items {
    [super setItems:items];
    if (self.streamView) {
        for (StreamDataSource *dataSource in items) {
            dataSource.streamView = self.streamView;
        }
    }
    self.currentDataSource = [self.items firstObject];
}

- (void)setCurrentDataSource:(StreamDataSource *)currentDataSource {
    _currentDataSource = currentDataSource;
    [self reload];
}

- (void)setCurrentDataSourceAtIndex:(NSUInteger)index {
    if (index < self.items.count) {
        self.currentDataSource = [self.items objectAtIndex:index];
    }
}

- (NSUInteger)indexOfCurrentDataSource {
    return [self.items indexOfObject:self.currentDataSource];
}

- (IBAction)toggleSegment {
    NSArray *collection = self.items;
    if (collection.count > 0) {
        NSUInteger index = [collection indexOfObject:self.currentDataSource] + 1;
        self.currentDataSource = [collection objectAtIndex:(index < collection.count) ? index : 0];
    }
}

- (void)refresh:(WLObjectBlock)success failure:(WLFailureBlock)failure{
    [self.currentDataSource refresh:success failure:failure];
}

// MARK: - SegmentedControlDelegate

- (void)segmentedControl:(SegmentedControl *)control didSelectSegment:(NSInteger)segment {
    [self setCurrentDataSourceAtIndex:segment];
}

- (IBAction)segmentValueChanged:(SegmentedControl*)sender {
    [self setCurrentDataSourceAtIndex:sender.selectedSegment];
}

// MARK: - StreamViewDelegate

- (NSInteger)streamView:(StreamView*)streamView numberOfItemsInSection:(NSInteger)section {
    return [self.currentDataSource streamView:streamView numberOfItemsInSection:section];
}

- (id)streamView:(StreamView*)streamView viewForItem:(StreamItem*)item {
    return [self.currentDataSource streamView:streamView viewForItem:item];
}

- (StreamMetrics*)streamView:(StreamView*)streamView metricsAt:(StreamIndex*)index {
    return [self.currentDataSource streamView:streamView metricsAt:index];
}

- (NSInteger)streamViewNumberOfSections:(StreamView*)streamView {
    return [self.currentDataSource streamViewNumberOfSections:streamView];
}

- (void)streamView:(StreamView*)streamView didSelectItem:(StreamItem*)item {
    [self.currentDataSource streamView:streamView didSelectItem:item];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    [self.currentDataSource scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.currentDataSource scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.currentDataSource scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.currentDataSource scrollViewDidScroll:scrollView];
}

@end
