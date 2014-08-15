//
//  WLCandiesHistoryViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandiesHistoryViewSection.h"
#import "UIView+Shorthand.h"
#import "WLWrapRequest.h"
#import "WLGroupedSet.h"

static NSString* WLCandiesHistoryViewStubCell = @"WLCandiesHistoryViewStubCell";

@implementation WLCandiesHistoryViewSection

- (void)setup {
    [super setup];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:WLCandiesHistoryViewStubCell];
}

- (void)setCollectionView:(UICollectionView *)collectionView {
    [super setCollectionView:collectionView];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:WLCandiesHistoryViewStubCell];
}

//- (id)cell:(NSIndexPath *)indexPath {
//    WLGroup* group  = [self.entries.entries tryObjectAtIndex:indexPath.item];
//    if (!group.entries.nonempty || [group.date isToday]) {
//        return [self.collectionView dequeueReusableCellWithReuseIdentifier:WLCandiesHistoryViewStubCell forIndexPath:indexPath];;
//    }
//    return [super cell:indexPath];
//}

- (CGSize)size:(NSIndexPath *)indexPath {
//    WLGroup* group  = [self.entries.entries tryObjectAtIndex:indexPath.item];
//    if (!group.entries.nonempty || [group.date isToday]) {
//        return CGSizeMake(0.1, 0.1);
//    }
    return CGSizeMake(self.collectionView.width, (self.collectionView.width/2.5 + 28));
}

- (void)append:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLWrapRequest* request = (id)self.entries.request;
    request.page = ((self.entries.entries.count + 1)/WLAPIDatePageSize + 1);
    [super append:success failure:failure];
}

@end
