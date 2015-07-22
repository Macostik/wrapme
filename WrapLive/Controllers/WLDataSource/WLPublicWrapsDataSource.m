//
//  WLPublicWrapsDataSource.m
//  wrapLive
//
//  Created by Sergey Maximenko on 7/22/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPublicWrapsDataSource.h"
#import "WLLoadingView.h"

@implementation WLPublicWrapsDataSource

// MARK: - WLCollectionViewLayoutDelegate

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return [super collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    } else if ([kind isEqualToString:@"WLPublicWrapsHeaderView"]) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLPublicWrapsHeaderView" forIndexPath:indexPath];
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView*)collectionView sizeForItemAtIndexPath:(NSIndexPath*)indexPath {
    return CGSizeMake(collectionView.width, 60);
}

- (CGSize)collectionView:(UICollectionView*)collectionView sizeForSupplementaryViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return self.appendable ? CGSizeMake(collectionView.width, WLLoadingViewDefaultSize) : CGSizeZero;
    } else if ([kind isEqualToString:@"WLPublicWrapsHeaderView"] && indexPath.item == 0) {
        return CGSizeMake(collectionView.width, 88);
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView topSpacingForItemAtIndexPath:(NSIndexPath*)indexPath {
    return indexPath.item == 0 ? 5 : 0;
}

- (BOOL)collectionView:(UICollectionView*)collectionView applyContentSizeInsetForAttributes:(UICollectionViewLayoutAttributes*)attributes {
    return NO;
}

@end
