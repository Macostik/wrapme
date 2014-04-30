//
//  WLWrapCandiesCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapCandiesCell.h"
#import "WLWrapDate.h"
#import "NSDate+Formatting.h"
#import "WLWrapCandyCell.h"
#import "WLCandy.h"
#import "NSObject+NibAdditions.h"
#import "WLRefresher.h"
#import "NSArray+Additions.h"
#import "WLAPIManager.h"
#import "WLWrap.h"
#import "WLWrapBroadcaster.h"
#import "WLUploadingQueue.h"

@interface WLWrapCandiesCell () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, WLWrapBroadcastReceiver>

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) WLRefresher *refresher;

@property (nonatomic) BOOL shouldAppendMoreCandies;

@end

@implementation WLWrapCandiesCell

- (void)setShouldAppendMoreCandies:(BOOL)shouldAppendMoreCandies {
	_shouldAppendMoreCandies = shouldAppendMoreCandies;
	UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
	layout.footerReferenceSize = _shouldAppendMoreCandies ? CGSizeMake(100, 100) : CGSizeZero;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	self.shouldAppendMoreCandies = YES;
	[self.collectionView registerNib:[WLWrapCandyCell nib] forCellWithReuseIdentifier:[WLWrapCandyCell reuseIdentifier]];
	[[WLWrapBroadcaster broadcaster] addReceiver:self];
	__weak typeof(self)weakSelf = self;
	self.refresher = [WLRefresher refresherWithScrollView:self.collectionView refreshBlock:^(WLRefresher *refresher) {
		[weakSelf refreshCandies];
	}];
	self.refresher.colorScheme = WLRefresherColorSchemeOrange;
}

- (void)setupItemData:(WLWrapDate*)entry {
	self.dateLabel.text = [[entry.updatedAt stringWithFormat:@"MMM dd, YYYY"] uppercaseString];
	self.shouldAppendMoreCandies = [entry.candies count] >= 10;
	[self.collectionView reloadData];
	self.refresher.enabled = [entry.updatedAt isToday];
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapChanged:(WLWrap *)wrap {
	[self.collectionView reloadData];
}

- (void)refreshCandies {
	__weak typeof(self)weakSelf = self;
	WLWrapDate* currentWrapDay = self.item;
	WLWrapDate* wrapDay = [currentWrapDay copy];
	wrapDay.candies = nil;
	[[WLAPIManager instance] candies:self.wrap date:wrapDay success:^(id object) {
		weakSelf.shouldAppendMoreCandies = [object count] == WLAPIGeneralPageSize;
		currentWrapDay.candies = object;
		[[WLUploadingQueue instance] updateWrap:weakSelf.wrap];
		[weakSelf.collectionView reloadData];
		[weakSelf.refresher endRefreshing];
	} failure:^(NSError *error) {
		weakSelf.shouldAppendMoreCandies = NO;
		[error show];
		[weakSelf.refresher endRefreshing];
	}];
}

- (void)appendCandies {
	WLWrapDate* wrapDay = self.item;
	__weak typeof(self)weakSelf = self;
	[[WLAPIManager instance] candies:self.wrap date:wrapDay success:^(id object) {
		weakSelf.shouldAppendMoreCandies = [object count] == WLAPIGeneralPageSize;
		wrapDay.candies = (id)[wrapDay.candies arrayByAddingObjectsFromArray:object];
		[weakSelf.collectionView reloadData];
	} failure:^(NSError *error) {
		weakSelf.shouldAppendMoreCandies = NO;
		[error show];
	}];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	WLWrapDate* wrapDay = self.item;
	return [wrapDay.candies count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	WLWrapCandyCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WLWrapCandyCell reuseIdentifier] forIndexPath:indexPath];
	WLWrapDate* wrapDay = self.item;
	cell.item = [wrapDay.candies objectAtIndex:indexPath.item];
	cell.wrap = self.wrap;
	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	[self performSelector:@selector(appendCandies) withObject:nil afterDelay:0.0f];
	static NSString* WLWrapDayLoadingViewIdentifier = @"WLWrapDayLoadingView";
	return [collectionView dequeueReusableSupplementaryViewOfKind:kind
											  withReuseIdentifier:WLWrapDayLoadingViewIdentifier
													 forIndexPath:indexPath];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	WLWrapDate* wrapDay = self.item;
	WLCandy * candy = [wrapDay.candies objectAtIndex:indexPath.item];
	if (candy.uploadingItem == nil) {
		[self.delegate wrapCandiesCell:self didSelectCandy:candy];
	}
}

@end
