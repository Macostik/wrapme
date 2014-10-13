//
//  WLCandiesViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandiesViewSection.h"
#import "UIScrollView+Additions.h"
#import "WLCandyCell.h"
#import "WLGroupedSet.h"
#import "WLSupportFunctions.h"

@implementation WLCandiesViewSection

- (CGSize)size:(NSIndexPath *)indexPath {
    CGFloat size = self.collectionView.bounds.size.width/2.5;
    return CGSizeMake(size, self.collectionView.bounds.size.height);
}

- (CGFloat)fixedContentOffset:(CGFloat)offset {
    CGFloat size = self.collectionView.bounds.size.width/2.5 + WLCandyCellSpacing;
    return Smoothstep(0, self.collectionView.maximumContentOffset.x, roundf(offset/size)*size);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    WLGroup* group = (id)self.entries;
    group.offset = scrollView.contentOffset;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGFloat offset = targetContentOffset->x;
    if (offset <= 0 || offset >= self.collectionView.maximumContentOffset.x) {
		return;
	}
    targetContentOffset->x = [self fixedContentOffset:offset];
}

@end
