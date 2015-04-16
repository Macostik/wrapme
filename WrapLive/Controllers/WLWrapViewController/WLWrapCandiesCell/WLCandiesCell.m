//
//  WLWrapCandiesCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandiesCell.h"
#import "WLCandyCell.h"
#import "NSObject+NibAdditions.h"
#import "WLRefresher.h"
#import "UIScrollView+Additions.h"
#import "WLHistoryItemDataSource.h"
#import "WLChronologicalEntryPresenter.h"

@interface WLCandiesCell ()

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) WLHistoryItemDataSource* dataSource;

@end

@implementation WLCandiesCell

- (void)awakeFromNib {
	[super awakeFromNib];
    UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
    layout.minimumLineSpacing = WLConstants.pixelSize;
    layout.sectionInset = UIEdgeInsetsMake(0, WLCandyCellSpacing, 0, WLCandyCellSpacing);
    
    WLHistoryItemDataSource* dataSource = [WLHistoryItemDataSource dataSource:self.collectionView];
    dataSource.cellIdentifier = WLCandyCellIdentifier;
    __weak typeof(self)weakSelf = self;
    [dataSource setItemSizeBlock:^CGSize(WLCandy *candy, NSUInteger index) {
        CGFloat size = weakSelf.collectionView.width/2.5;
        return CGSizeMake(size, weakSelf.collectionView.height);
    }];
    [dataSource setSelectionBlock:^ (id entry) {
        [WLChronologicalEntryPresenter presentEntry:entry animated:YES];
    }];
    self.dataSource = dataSource;
}

- (void)setup:(WLHistoryItem*)item {
    self.dataSource.items = item;
	self.dateLabel.text = [item.date string];
    [self.collectionView layoutIfNeeded];
    [self.collectionView trySetContentOffset:item.offset];
}

@end
