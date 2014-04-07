//
//  WLWrapCandiesCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapCandiesCell.h"
#import "WLWrapDay.h"
#import "NSDate+Formatting.h"
#import "WLWrapCandyCell.h"
#import "WLCandy.h"
#import "NSObject+NibAdditions.h"
#import "WLRefresher.h"
#import "NSArray+Additions.h"

@interface WLWrapCandiesCell () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) WLRefresher *refresher;

@property (nonatomic) BOOL shouldAppendMoreCandies;

@end

@implementation WLWrapCandiesCell

- (void)awakeFromNib {
	[super awakeFromNib];
	[self.collectionView registerNib:[WLWrapCandyCell nib] forCellWithReuseIdentifier:[WLWrapCandyCell reuseIdentifier]];
	self.refresher = [WLRefresher refresherWithScrollView:self.collectionView refreshBlock:^(WLRefresher *refresher) {
		[self.refresher performSelector:@selector(endRefreshing) withObject:nil afterDelay:1];
	}];
}

- (void)setupItemData:(WLWrapDay*)entry {
	self.shouldAppendMoreCandies = [entry.candies count] % 10 == 0;
	self.dateLabel.text = [entry.updatedAt stringWithFormat:@"MMM dd, YYYY"];
	[self.collectionView reloadData];
}

- (void)appendCandies {
	// this is temporary code
	WLWrapDay* wrapDay = self.item;
	self.shouldAppendMoreCandies = [wrapDay.candies count] % 10 == 0;
	wrapDay.candies = [wrapDay.candies arrayByAddingObjectsFromArray:wrapDay.candies];
	[self.collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	WLWrapDay* wrapDay = self.item;
	return [wrapDay.candies count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	WLWrapCandyCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WLWrapCandyCell reuseIdentifier] forIndexPath:indexPath];
	WLWrapDay* wrapDay = self.item;
	cell.item = [wrapDay.candies objectAtIndex:indexPath.item];
	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
		[self performSelector:@selector(appendCandies) withObject:nil afterDelay:0.0f];
		static NSString* WLWrapDayLoadingViewIdentifier = @"WLWrapDayLoadingView";
		return [collectionView dequeueReusableSupplementaryViewOfKind:kind
												  withReuseIdentifier:WLWrapDayLoadingViewIdentifier
														 forIndexPath:indexPath];
	}
	return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
	if (self.shouldAppendMoreCandies) {
		return CGSizeMake(100, 100);
	}
	return CGSizeZero;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	WLWrapDay* wrapDay = self.item;
	WLCandy * candy = [wrapDay.candies objectAtIndex:indexPath.item];
	[self.delegate wrapCandiesCell:self didSelectCandy:candy];
}

@end
