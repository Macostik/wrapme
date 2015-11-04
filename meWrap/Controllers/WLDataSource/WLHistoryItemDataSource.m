//
//  WLCandiesViewSection.m
//  meWrap
//
//  Created by Ravenpod on 8/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLHistoryItemDataSource.h"
#import "WLCandyCell.h"
#import "WLHistoryItem.h"

@implementation WLHistoryItemDataSource

- (CGFloat)fixedContentOffset:(CGFloat)offset {
    CGFloat size = self.streamView.bounds.size.width/2.5 + self.layoutSpacing;
    return Smoothstep(0, self.streamView.maximumContentOffset.x, roundf(offset/size)*size);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    WLHistoryItem* group = (id)self.items;
    group.offset = scrollView.contentOffset;
    [super scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGFloat offset = targetContentOffset->x;
    CGFloat maxOffset = scrollView.maximumContentOffset.x;
    if (offset > 0 && ABS(offset - maxOffset) > 1) {
		targetContentOffset->x = [self fixedContentOffset:offset];
	}
    [super scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

@end
