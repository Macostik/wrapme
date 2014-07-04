//
//  WLWrapCandiesCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandiesCell.h"
#import "NSDate+Formatting.h"
#import "WLCandyCell.h"
#import "WLCandy.h"
#import "NSObject+NibAdditions.h"
#import "WLRefresher.h"
#import "NSArray+Additions.h"
#import "WLAPIManager.h"
#import "WLWrap.h"
#import "NSDate+Additions.h"
#include "WLSupportFunctions.h"
#import "WLGroupedSet.h"
#import "UIScrollView+Additions.h"

@interface WLCandiesCell () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, WLCandyCellDelegate, WLGroupDelegate>

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) WLRefresher *refresher;

@property (nonatomic) BOOL shouldAppendMoreCandies;

@end

@implementation WLCandiesCell
{
	BOOL loading;
}

- (void)setShouldAppendMoreCandies:(BOOL)shouldAppendMoreCandies {
	_shouldAppendMoreCandies = shouldAppendMoreCandies;
	UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
    CGFloat size = self.collectionView.bounds.size.width/2.5;
	layout.footerReferenceSize = _shouldAppendMoreCandies ? CGSizeMake(size, size) : CGSizeZero;
}

- (void)awakeFromNib {
	[super awakeFromNib];
    UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
    layout.minimumLineSpacing = WLCandyCellSpacing;
    layout.sectionInset = UIEdgeInsetsMake(0, WLCandyCellSpacing, 0, WLCandyCellSpacing);
	self.shouldAppendMoreCandies = YES;
	[self.collectionView registerNib:[WLCandyCell nib] forCellWithReuseIdentifier:WLCandyCellIdentifier];
	self.refresher = [WLRefresher refresherWithScrollView:self.collectionView target:self action:@selector(refreshCandies) colorScheme:WLRefresherColorSchemeOrange];
}

- (void)setupItemData:(WLGroup*)group {
    group.delegate = self;
	self.dateLabel.text = [group.name uppercaseString];
	self.shouldAppendMoreCandies = [group.candies count] >= 10;
	[self.collectionView reloadData];
    [self.collectionView trySetContentOffset:group.offset];
	loading = NO;
}

- (void)setRefreshable:(BOOL)refreshable {
    self.refresher.enabled = refreshable;
}

- (void)refreshCandies {
	__weak typeof(self)weakSelf = self;
    WLGroup* group = self.item;
    WLCandy* candy = [[group candies] firstObject];
    [candy newerCandies:YES success:^(NSOrderedSet *array) {
        [group addCandies:array];
		[weakSelf.refresher endRefreshing];
    } failure:^(NSError *error) {
		[error show];
		[weakSelf.refresher endRefreshing];
    }];
}

- (void)appendCandies {
	if (loading) {
		return;
	}
	loading = YES;
	__weak typeof(self)weakSelf = self;
    WLGroup* group = self.item;
    WLCandy* candy = [[group candies] lastObject];
    [candy olderCandies:YES success:^(NSOrderedSet *array) {
        NSUInteger count = [group.candies count];
        [group addCandies:array];
        weakSelf.shouldAppendMoreCandies = ([group.candies count] > count);
		[weakSelf fixContentOffset];
		loading = NO;
    } failure:^(NSError *error) {
        weakSelf.shouldAppendMoreCandies = NO;
		[error show];
		loading = NO;
    }];
}

#pragma mark - WLGroupDelegate

- (void)groupsChanged:(WLGroup *)group {
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	WLGroup* group = self.item;
	return [group.candies count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	WLCandyCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:WLCandyCellIdentifier forIndexPath:indexPath];
	WLGroup* group = self.item;
	cell.item = [group.candies tryObjectAtIndex:indexPath.item];
	cell.delegate = self;
	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	[self performSelector:@selector(appendCandies) withObject:nil afterDelay:0.0f];
	static NSString* WLWrapDayLoadingViewIdentifier = @"WLWrapDayLoadingView";
	return [collectionView dequeueReusableSupplementaryViewOfKind:kind
											  withReuseIdentifier:WLWrapDayLoadingViewIdentifier
													 forIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat size = collectionView.bounds.size.width/2.5;
    return CGSizeMake(size, size);
}

- (void)fixContentOffset {
    CGFloat offset = self.collectionView.contentOffset.x;
    if (offset <= 0 || offset >= self.collectionView.maximumContentOffset.x) {
		return;
	}
    CGFloat size = self.collectionView.bounds.size.width/2.5;
    CGFloat x = CGFLOAT_MAX;
    for (UICollectionViewCell* cell in [self.collectionView visibleCells]) {
        if (cell.frame.origin.x < x) {
            x = cell.frame.origin.x;
        }
    }
    offset = offset - x > size/2 ? (x + size) : (x - WLCandyCellSpacing);
    [self.collectionView trySetContentOffset:CGPointMake(offset, 0) animated:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (!decelerate) {
		[self fixContentOffset];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (!scrollView.tracking) {
        [self fixContentOffset];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    WLGroup* group = self.item;
    group.offset = scrollView.contentOffset;
}

#pragma mark - WLWrapCandyCellDelegate

- (void)candyCell:(WLCandyCell *)cell didSelectCandy:(WLCandy *)candy {
	[self.delegate candiesCell:self didSelectCandy:candy];
}

@end
