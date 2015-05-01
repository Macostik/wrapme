//
//  WLSectionedDataSource.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSectionedDataSource.h"
#import "WLLoadingView.h"
#import "WLEntryCell.h"
#import "WLEntryReusableView.h"

@implementation WLSectionedDataSource

- (void)awakeAfterInit {
    [super awakeAfterInit];
    self.numberOfDescendants = 1;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.numberOfItems;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.numberOfDescendantsBlock) {
        return self.numberOfDescendantsBlock([self itemAtIndex:section]);
    }
    return self.numberOfDescendants;
}

- (NSUInteger)indexFromIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLEntryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.cellIdentifier forIndexPath:indexPath];
    if (self.descendantAtIndexBlock) {
        cell.entry = self.descendantAtIndexBlock(indexPath.item, [self itemAtIndex:indexPath.section]);
    } else {
        cell.entry = [self itemAtIndex:[self indexFromIndexPath:indexPath]];
    }
    if (self.configureCellForItemBlock) self.configureCellForItemBlock(cell, cell.entry);
    cell.selectionBlock = self.selectionBlock;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger index = [self indexFromIndexPath:indexPath];
    return  self.itemSizeBlock ? self.itemSizeBlock([self itemAtIndex:index], index) : self.itemSize;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    WLEntryReusableView *entryReusableView = nil;
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        entryReusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:self.headerIdentifier forIndexPath:indexPath];
    } else {
        if (self.appendable && indexPath.section == self.numberOfItems - 1) {
            WLLoadingView* loadingView = [WLLoadingView dequeueInCollectionView:self.collectionView indexPath:indexPath];
            loadingView.error = NO;
            [self append:nil failure:^(NSError *error) {
                [error showIgnoringNetworkError];
                if (error) loadingView.error = YES;
            }];
            return loadingView;
        } else {
            entryReusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:self.footerIdentifier forIndexPath:indexPath];
        }
    }
    entryReusableView.entry = [self itemAtIndex:indexPath.section];
    entryReusableView.selectionBlock = self.selectionBlock;
    return entryReusableView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (self.appendable && section == self.numberOfItems - 1) {
        UICollectionViewFlowLayout* layout = (id)collectionView.collectionViewLayout;
        if (layout.scrollDirection == UICollectionViewScrollDirectionVertical) {
            return CGSizeMake(collectionView.bounds.size.width, WLLoadingViewDefaultSize);
        } else {
            return CGSizeMake(WLLoadingViewDefaultSize, collectionView.bounds.size.height);
        }
    }
    return  self.footerSizeBlock ? self.footerSizeBlock() : self.footerSize;
}

@end
