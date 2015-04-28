//
//  WLPaginatedCollectionViewLayout.m
//  WrapLive
//
//  Created by Yura Granchenko on 27/04/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPaginatedCollectionViewLayout.h"

@implementation WLPaginatedCollectionViewLayout

- (UICollectionViewLayoutAttributes*)finalLayoutAttributesForDisappearingSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)elementIndexPath {
    
    UICollectionViewLayoutAttributes *attributes = [super finalLayoutAttributesForDisappearingSupplementaryElementOfKind:elementKind atIndexPath:elementIndexPath];
    attributes.size = CGSizeZero;

    return attributes;
}

@end
