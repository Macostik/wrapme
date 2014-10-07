//
//  WLHomeCandiesViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/12/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLHomeCandiesViewSection.h"
#import "WLWrapCell.h"
#import "WLCandyCell.h"

@implementation WLHomeCandiesViewSection

- (NSUInteger)numberOfEntries {
	return ([self.entries.entries count] > WLHomeTopWrapCandiesLimit_2) ? WLHomeTopWrapCandiesLimit : WLHomeTopWrapCandiesLimit_2;
}

- (CGSize)size:(NSIndexPath *)indexPath {
    CGFloat size = floorf(self.collectionView.bounds.size.width/3.0f) - WLCandyCellSpacing;
    return CGSizeMake(size, size);
}

- (id)cell:(NSIndexPath *)indexPath {
	if (indexPath.item < [self.entries.entries count]) {
		return [super cell:indexPath];
	} else {
        return [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CandyPlaceholderCell" forIndexPath:indexPath];
	}
}

@end
