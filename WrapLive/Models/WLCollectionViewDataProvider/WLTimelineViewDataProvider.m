//
//  WLTimelineViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTimelineViewDataProvider.h"
#import "UIView+Shorthand.h"
#import "WLTimelineEvent.h"
#import "WLTimeline.h"
#import "WLTimelineEvent.h"
#import "WLTimelineEventCell.h"
#import "WLTimelineEventHeaderView.h"
#import "WLCandyCell.h"

@interface WLTimelineViewDataProvider () <WLPaginatedSetDelegate>

@end

@implementation WLTimelineViewDataProvider

- (void)setTimeline:(WLTimeline *)timeline {
    _timeline = timeline;
    timeline.delegate = self;
    [self reload];
}

- (void)append:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    if (!self.timeline.request.loading) {
        [self.timeline older:success failure:failure];
    } else if (failure) {
        failure(nil);
    }
}

- (void)refresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    if (!self.timeline.request.loading) {
        [self.timeline newer:success failure:failure];
    } else if (failure) {
        failure(nil);
    }
}

- (void)append {
    [self append:nil failure:^(NSError *error) {
        [error showIgnoringNetworkError];
    }];
}

- (void)refresh {
    
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.timeline.entries count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    WLTimelineEvent* event = [self.timeline.entries tryObjectAtIndex:section];
    return [event.images count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLTimelineEvent* event = [self.timeline.entries tryObjectAtIndex:indexPath.section];
    WLEntryCell* cell = nil;
    if (event.type == WLTimelineEventTypeComment) {
        static NSString* identifier = @"WLTimelineEventCommentCell";
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    } else {
        static NSString* identifier = @"WLTimelineEventPhotoCell";
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    }
    cell.selection = self.selection;
    cell.entry = [event.images tryObjectAtIndex:indexPath.item];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        WLTimelineEvent* event = [self.timeline.entries tryObjectAtIndex:indexPath.section];
        static NSString* identifier = @"WLTimelineEventHeaderView";
        WLTimelineEventHeaderView* view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
        view.event = event;
        return view;
    } else {
        [self append];
        return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLLoadingView" forIndexPath:indexPath];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(collectionView.width, 28);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (section == [self.timeline.entries count] - 1 && !self.timeline.completed) {
        return CGSizeMake(collectionView.width, 88);
    } else {
        return CGSizeZero;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLTimelineEvent* event = [self.timeline.entries tryObjectAtIndex:indexPath.section];
    if (event.type == WLTimelineEventTypeComment) {
        return CGSizeMake(collectionView.width, 66);
    } else {
        return CGSizeMake(collectionView.width/3, collectionView.width/3);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - WLPaginatedSetDelegate

- (void)paginatedSetChanged:(WLPaginatedSet *)group {
    [self reload];
}

@end
