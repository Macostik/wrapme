//
//  WLWrapCandiesCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandiesCell.h"
#import "WLDate.h"
#import "NSDate+Formatting.h"
#import "WLCandyCell.h"
#import "WLCandy.h"
#import "NSObject+NibAdditions.h"
#import "WLRefresher.h"
#import "NSArray+Additions.h"
#import "WLAPIManager.h"
#import "WLWrap.h"
#import "WLWrapBroadcaster.h"
#import "NSDate+Additions.h"
#include "WLSupportFunctions.h"

@interface WLCandiesCell () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, WLWrapBroadcastReceiver, WLCandyCellDelegate>

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
	layout.footerReferenceSize = _shouldAppendMoreCandies ? CGSizeMake(100, 100) : CGSizeZero;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	self.shouldAppendMoreCandies = YES;
	[self.collectionView registerNib:[WLCandyCell nib] forCellWithReuseIdentifier:[WLCandyCell reuseIdentifier]];
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
	self.refresher = [WLRefresher refresherWithScrollView:self.collectionView target:self action:@selector(refreshCandies) colorScheme:WLRefresherColorSchemeOrange];
}

- (void)setupItemData:(WLDate*)date {
	self.dateLabel.text = [date.dateString uppercaseString];
	self.shouldAppendMoreCandies = [date.candies count] >= 10;
	[self.collectionView reloadData];
	self.refresher.enabled = [date.date isToday];
	self.collectionView.contentOffset = CGPointZero;
	loading = NO;
}

- (void)refreshCandies {
	__weak typeof(self)weakSelf = self;
    WLDate* date = self.item;
    WLCandy* candy = [[date candies] firstObject];
    [candy newerCandies:YES success:^(NSOrderedSet *array) {
        [date addCandies:array];
		[weakSelf.collectionView reloadData];
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
    WLDate* date = self.item;
    WLCandy* candy = [[date candies] lastObject];
    [candy olderCandies:YES success:^(NSOrderedSet *array) {
        weakSelf.shouldAppendMoreCandies = array.nonempty;
        [date addCandies:array];
		[weakSelf.collectionView reloadData];
		[weakSelf fixContentOffset];
		loading = NO;
    } failure:^(NSError *error) {
        weakSelf.shouldAppendMoreCandies = NO;
		[error show];
		loading = NO;
    }];
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapChanged:(WLWrap *)wrap {
	[self.collectionView reloadData];
}

- (WLWrap *)broadcasterPreferedWrap:(WLWrapBroadcaster *)broadcaster {
    WLDate* date = self.item;
    WLCandy* candy = [[date candies] firstObject];
    return candy.wrap;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	WLDate* wrapDay = self.item;
	return [wrapDay.candies count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	WLCandyCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WLCandyCell reuseIdentifier] forIndexPath:indexPath];
	WLDate* wrapDay = self.item;
	cell.item = [wrapDay.candies objectAtIndex:indexPath.item];
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

- (void)fixContentOffset {
	CGFloat offset = self.collectionView.contentOffset.x;
	offset = roundf(offset / 106.0f) * 106.0f;
	if (IsInBounds(0, self.collectionView.contentSize.width - self.collectionView.bounds.size.width, offset)) {
		[self.collectionView setContentOffset:CGPointMake(offset, 0) animated:YES];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (!decelerate) {
		[self fixContentOffset];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	[self fixContentOffset];
}

#pragma mark - WLWrapCandyCellDelegate

- (void)candyCell:(WLCandyCell *)cell didSelectCandy:(WLCandy *)candy {
	if (candy.uploading == nil) {
		[self.delegate candiesCell:self didSelectCandy:candy];
	}
}

@end
