//
//  WLRecentCandiesView.m
//  wrapLive
//
//  Created by Sergey Maximenko on 7/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLRecentCandiesView.h"
#import "WLBasicDataSource.h"
#import "WLCandyCell.h"

@interface WLRecentCandiesView ()

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) WLBasicDataSource* dataSource;

@end

@implementation WLRecentCandiesView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    WLBasicDataSource* dataSource = [WLBasicDataSource dataSource:self.collectionView];
    dataSource.cellIdentifier = WLCandyCellIdentifier;
    dataSource.minimumLineSpacing = WLCandyCellSpacing;
    dataSource.sectionLeftInset = dataSource.sectionRightInset = WLCandyCellSpacing;
    [dataSource setNumberOfItemsBlock:^NSUInteger {
        return ([dataSource.items count] > WLHomeTopWrapCandiesLimit_2) ? WLHomeTopWrapCandiesLimit : WLHomeTopWrapCandiesLimit_2;
    }];
    [dataSource setCellIdentifierForItemBlock:^NSString *(id item, NSUInteger index) {
        return (index < [dataSource.items count]) ? WLCandyCellIdentifier : @"WLCandyPlaceholderCell";
    }];
    [dataSource setItemSizeBlock:^CGSize(id item, NSUInteger index) {
        int size = (WLConstants.screenWidth - 2.0f)/3.0f;
        return CGSizeMake(size, size);
    }];
    self.dataSource = dataSource;
}

- (void)setup:(WLWrap*)wrap {
    self.dataSource.items = [[NSMutableOrderedSet orderedSetWithSet:wrap.candies] sortByUpdatedAt];
}

@end
