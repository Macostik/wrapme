//
//  WLSegmentedDataSource.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSegmentedDataSource.h"
#import "SegmentedControl.h"

@interface WLSegmentedDataSource () <SegmentedControlDelegate>

@end

@implementation WLSegmentedDataSource

- (void)setCollectionView:(UICollectionView *)collectionView {
    [super setCollectionView:collectionView];
    if (collectionView) {
        for (WLDataSource *dataSource in self.items) {
            dataSource.collectionView = collectionView;
        }
    }
    
    self.currentDataSource = self.currentDataSource ? : [self.items firstObject];
}

- (void)setItems:(NSMutableArray *)items {
    [super setItems:items];
    if (self.collectionView) {
        for (WLDataSource *dataSource in items) {
            dataSource.collectionView = self.collectionView;
        }
    }
    self.currentDataSource = [self.items firstObject];
}

- (void)addDataSource:(WLDataSource*)dataSource {
    if (!self.items) self.items = [NSMutableArray array];
    if (![self.items containsObject:dataSource]) {
        [self.items addObject:dataSource];
        dataSource.collectionView = self.collectionView;
        [self reload];
    }
}

- (void)removeDataSource:(WLDataSource*)dataSource {
    if ([self.items containsObject:dataSource]) {
        [self.items removeObject:dataSource];
        [self reload];
    }
}

- (void)setCurrentDataSource:(WLDataSource *)currentDataSource {
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

// MARK: - SegmentedControlDelegate

- (void)segmentedControl:(SegmentedControl *)control didSelectSegment:(NSInteger)segment {
    [self setCurrentDataSourceAtIndex:segment];
}

- (IBAction)segmentValueChanged:(SegmentedControl*)sender {
    [self setCurrentDataSourceAtIndex:sender.selectedSegment];
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.currentDataSource numberOfSectionsInCollectionView:collectionView];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.currentDataSource collectionView:collectionView numberOfItemsInSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.currentDataSource collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return [self.currentDataSource collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return [self.currentDataSource collectionView:collectionView layout:collectionViewLayout referenceSizeForHeaderInSection:section];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return [self.currentDataSource collectionView:collectionView layout:collectionViewLayout referenceSizeForFooterInSection:section];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.currentDataSource collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [self.currentDataSource collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [self.currentDataSource collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:section];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return [self.currentDataSource collectionView:collectionView layout:collectionViewLayout insetForSectionAtIndex:section];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.currentDataSource collectionView:collectionView didSelectItemAtIndexPath:indexPath];
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
    [super scrollViewDidScroll:scrollView];
    [self.currentDataSource scrollViewDidScroll:scrollView];
}

@end
