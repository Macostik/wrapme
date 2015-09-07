//
//  WLWrapCandiesCell.m
//  meWrap
//
//  Created by Ravenpod on 26.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
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
    WLHistoryItemDataSource* dataSource = [WLHistoryItemDataSource dataSource:self.collectionView];
    dataSource.minimumLineSpacing = dataSource.sectionLeftInset = dataSource.sectionRightInset = WLConstants.pixelSize;
    dataSource.cellIdentifier = WLCandyCellIdentifier;
    __weak typeof(self)weakSelf = self;
    [dataSource setItemSizeBlock:^CGSize(WLCandy *candy, NSUInteger index) {
        CGFloat size = weakSelf.collectionView.width/2.5;
        return CGSizeMake(size, weakSelf.collectionView.height);
    }];
    self.dataSource = dataSource;
    self.dataSource.headerAnimated = YES;
}

- (void)setup:(WLHistoryItem*)item {
    self.dataSource.items = item;
	self.dateLabel.text = [item.date stringWithDateStyle:NSDateFormatterMediumStyle];
    [self.collectionView layoutIfNeeded];
    [self.collectionView trySetContentOffset:item.offset];
}

@end
