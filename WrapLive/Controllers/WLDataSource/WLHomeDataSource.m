//
//  WLHomeViewSection.m
//  moji
//
//  Created by Ravenpod on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLHomeDataSource.h"
#import "WLWrapCell.h"
#import "WLOperationQueue.h"
#import "UIView+Shorthand.h"
#import "WLEntryCell.h"
#import "WLLoadingView.h"

@interface WLHomeDataSource ()

@end

@implementation WLHomeDataSource

- (void)setItems:(id<WLBaseOrderedCollection>)items {
    if (items.count > 0) self.wrap = [items objectAtIndex:0];
    [super setItems:items];
}

- (void)setWrap:(WLWrap *)wrap {
    if (_wrap != wrap) {
        _wrap = wrap;
        if (wrap) [self fetchTopWrapIfNeeded:wrap];
    }
}

- (void)fetchTopWrapIfNeeded:(WLWrap*)wrap {
    if ([wrap.candies count] < WLHomeTopWrapCandiesLimit) {
        runUnaryQueuedOperation(WLOperationFetchingDataQueue, ^(WLOperation *operation) {
            if (!wrap.valid) {
                [operation finish];
                return;
            }
            [wrap fetch:WLWrapContentTypeRecent success:^(NSSet* set) {
                [operation finish];
            } failure:^(NSError *error) {
                [operation finish];
            }];
        });
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    self.wrap = [self.items tryAt:0];
    return [super collectionView:collectionView numberOfItemsInSection:section];
}

// MARK: - WLCollectionViewLayoutDelegate

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return [super collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    } else if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        WLRecentCandiesView *candiesView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"WLRecentCandiesView" forIndexPath:indexPath];
        self.candiesView = candiesView;
        candiesView.entry = self.wrap;
        return candiesView;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView*)collectionView sizeForItemAtIndexPath:(NSIndexPath*)indexPath {
    return CGSizeMake(collectionView.width, indexPath.item == 0 ? 70 : 60);
}

- (CGSize)collectionView:(UICollectionView*)collectionView sizeForSupplementaryViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return self.appendable ? CGSizeMake(collectionView.width, WLLoadingViewDefaultSize) : CGSizeZero;
    } else if ([kind isEqualToString:UICollectionElementKindSectionHeader] && indexPath.item == 0) {
        int size = (collectionView.width - 2.0f)/3.0f;;
        return CGSizeMake(collectionView.width, ([self.wrap.candies count] > WLHomeTopWrapCandiesLimit_2 ? 2*size : size) + 5);
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView topSpacingForItemAtIndexPath:(NSIndexPath*)indexPath {
    return indexPath.item == 1 ? 5 : 0;
}

- (BOOL)collectionView:(UICollectionView*)collectionView applyContentSizeInsetForAttributes:(UICollectionViewLayoutAttributes*)attributes {
    return NO;
}

@end
