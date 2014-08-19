//
//  WLCandiesLiveViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandiesLiveViewSection.h"
#import "WLCandyCell.h"
#import "WLWrapRequest.h"
#import "WLGroupedSet.h"

@implementation WLCandiesLiveViewSection

- (void)refresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [self.wrapRequest newer:^(NSOrderedSet *orderedSet) {
        [weakSelf.entries handleResponse:orderedSet success:success];
    } failure:failure];
}

- (void)append:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    if (self.entries.entries.nonempty) {
        [super append:success failure:failure];
    } else {
        [self refresh:success failure:failure];
    }
}

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
