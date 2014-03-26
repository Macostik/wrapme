//
//  WLWrapCandiesCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapCandiesCell.h"
#import "WLWrap.h"
#import "NSDate+Formatting.h"
#import "WLWrapCandyCell.h"

@interface WLWrapCandiesCell () <UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation WLWrapCandiesCell

- (void)setupItemData:(WLWrap*)entry {
	self.dateLabel.text = [entry.createdAt stringWithFormat:@"MMM dd, YYYY"];
	[self.collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	WLWrap* wrap = self.item;
	return [wrap.candies count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	WLWrapCandyCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WLWrapCandyCell reuseIdentifier] forIndexPath:indexPath];
	WLWrap* wrap = self.item;
	cell.item = [wrap.candies objectAtIndex:indexPath.item];
	return cell;
}

@end
