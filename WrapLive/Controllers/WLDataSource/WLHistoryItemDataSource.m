//
//  WLCandiesViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLHistoryItemDataSource.h"
#import "UIScrollView+Additions.h"
#import "WLCandyCell.h"
#import "WLHistory.h"

@implementation WLHistoryItemDataSource

- (CGFloat)fixedContentOffset:(CGFloat)offset {
    CGFloat size = self.collectionView.bounds.size.width/2.5 + WLCandyCellSpacing;
    return Smoothstep(0, self.collectionView.maximumContentOffset.x, roundf(offset/size)*size);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    WLHistoryItem* group = (id)self.items;
    group.offset = scrollView.contentOffset;
    [super scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGFloat offset = targetContentOffset->x;
    if (IsInBounds(0, scrollView.maximumContentOffset.x, offset)) {
		targetContentOffset->x = [self fixedContentOffset:offset];
	}
    [super scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

@end
