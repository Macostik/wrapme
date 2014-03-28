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

@interface WLWrapCandiesCell () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation WLWrapCandiesCell

- (void)setupItemData:(WLWrapDay*)entry {
	self.dateLabel.text = [entry.modified stringWithFormat:@"MMM dd, YYYY"];
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

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	WLWrapDay* wrapDay = self.item;
	WLCandy * candy = [wrapDay.candies objectAtIndex:indexPath.item];
	[self.delegate wrapCandiesCell:self didSelectCandy:candy];
}

@end
