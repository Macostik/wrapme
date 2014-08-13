//
//  WLCandiesLiveViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandiesLiveViewSection.h"
#import "WLCandyCell.h"

@implementation WLCandiesLiveViewSection

- (CGSize)size:(NSIndexPath *)indexPath {
    CGFloat size = self.collectionView.bounds.size.width/3.0f - WLCandyCellSpacing;
    return CGSizeMake(size, size);
}

- (CGFloat)minimumLineSpacing:(NSUInteger)section {
    return WLCandyCellSpacing;
}

- (UIEdgeInsets)sectionInsets:(NSUInteger)section {
    return UIEdgeInsetsMake(0, WLCandyCellSpacing, 0, WLCandyCellSpacing);
}

@end
