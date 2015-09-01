//
//  WLComposedDataSource.m
//  moji
//
//  Created by Ravenpod on 1/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLComposedDataSource.h"
#import "WLOperationQueue.h"

@implementation WLComposedDataSource

@dynamic items;

- (void)setCollectionView:(UICollectionView *)collectionView {
    [super setCollectionView:collectionView];
    if (collectionView) {
        for (WLDataSource *dataSource in self.items) {
            dataSource.collectionView = collectionView;
        }
    }
}

- (void)setItems:(NSMutableArray *)items {
    [super setItems:items];
    if (self.collectionView) {
        for (WLDataSource *dataSource in items) {
            dataSource.collectionView = self.collectionView;
        }
    }
    [self reload];
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

- (void)refresh:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    for (WLDataSource* section in self.items) {
        runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
            [section refresh:^(NSOrderedSet *orderedSet) {
                [operation finish:^{
                    if (success) success(weakSelf.items);
                }];
            } failure:^(NSError *error) {
                [operation finish:^{
                    if (failure) failure(error);
                    [error showIgnoringNetworkError];
                }];
            }];
        });
    }
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    WLDataSource *dataSource = [self itemAtIndex:section];
    return [dataSource collectionView:collectionView numberOfItemsInSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLDataSource *dataSource = [self itemAtIndex:indexPath.section];
    return [dataSource collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    WLDataSource *dataSource = [self itemAtIndex:indexPath.section];
    return [dataSource collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    WLDataSource *dataSource = [self itemAtIndex:section];
    return [dataSource collectionView:collectionView layout:collectionViewLayout referenceSizeForHeaderInSection:section];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    WLDataSource *dataSource = [self itemAtIndex:section];
    return [dataSource collectionView:collectionView layout:collectionViewLayout referenceSizeForFooterInSection:section];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLDataSource *dataSource = [self itemAtIndex:indexPath.section];
    return [dataSource collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    WLDataSource *dataSource = [self itemAtIndex:section];
    return [dataSource collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    WLDataSource *dataSource = [self itemAtIndex:section];
    return [dataSource collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:section];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    WLDataSource *dataSource = [self itemAtIndex:section];
    return [dataSource collectionView:collectionView layout:collectionViewLayout insetForSectionAtIndex:section];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    WLDataSource *dataSource = [self itemAtIndex:indexPath.section];
    return [dataSource collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    for (WLDataSource *dataSource in self.items) {
        [dataSource scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    for (WLDataSource *dataSource in self.items) {
        [dataSource scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    for (WLDataSource *dataSource in self.items) {
        [dataSource scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [super scrollViewDidScroll:scrollView];
    for (WLDataSource *dataSource in self.items) {
        [dataSource scrollViewDidScroll:scrollView];
    }
}

@end
