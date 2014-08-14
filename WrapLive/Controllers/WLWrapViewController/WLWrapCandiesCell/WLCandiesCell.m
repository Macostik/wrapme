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
#import "WLCollectionViewDataProvider.h"
#import "WLPaginatedViewSection.h"

@interface WLCandiesCell () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) WLCollectionViewDataProvider* dataProvider;

@property (strong, nonatomic) WLPaginatedViewSection* dataSection;


@end

@implementation WLCandiesCell

- (void)awakeFromNib {
	[super awakeFromNib];
    UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
    layout.minimumLineSpacing = WLCandyCellSpacing;
    layout.sectionInset = UIEdgeInsetsMake(0, WLCandyCellSpacing, 0, WLCandyCellSpacing);
    
    WLPaginatedViewSection* section = [[WLPaginatedViewSection alloc] initWithCollectionView:self.collectionView];
    section.reuseCellIdentifier = WLCandyCellIdentifier;
    section.selection = self.selection;
    self.dataSection = section;
    self.dataProvider = [WLCollectionViewDataProvider dataProvider:self.collectionView section:section];
}

- (void)setup:(WLGroup*)group {
    self.dataSection.entries = group;
	self.dateLabel.text = [group.name uppercaseString];
	self.dataSection.completed = [group.entries count] < 3;
    [self.collectionView trySetContentOffset:group.offset];
    [group.request cancel];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	WLGroup* group = self.entry;
	return [group.entries count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	WLCandyCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:WLCandyCellIdentifier forIndexPath:indexPath];
	WLGroup* group = self.entry;
	cell.entry = [group.entries tryObjectAtIndex:indexPath.item];
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
    WLGroup* group = self.entry;
    group.offset = scrollView.contentOffset;
}

@end
