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
#import "WLHistory.h"
#import "UIScrollView+Additions.h"
#import "WLCollectionViewDataProvider.h"
#import "WLCandiesViewSection.h"

@interface WLCandiesCell ()

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) WLCollectionViewDataProvider* dataProvider;

@property (strong, nonatomic) WLPaginatedViewSection* dataSection;


@end

@implementation WLCandiesCell

- (void)awakeFromNib {
	[super awakeFromNib];
    UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
    layout.minimumLineSpacing = WLConstants.pixelSize;
    layout.sectionInset = UIEdgeInsetsMake(0, WLCandyCellSpacing, 0, WLCandyCellSpacing);
    
    WLCandiesViewSection* section = [[WLCandiesViewSection alloc] initWithCollectionView:self.collectionView];
    section.reuseCellIdentifier = WLCandyCellIdentifier;
    section.selection = self.selection;
    self.dataSection = section;
    self.dataProvider = [WLCollectionViewDataProvider dataProvider:self.collectionView section:section];
}

- (void)setSelection:(WLObjectBlock)selection {
    [super setSelection:selection];
    self.dataSection.selection = selection;
}

- (void)setup:(WLHistoryItem*)item {
    self.dataSection.entries = item;
	self.dateLabel.text = [item.date string];
    [self.collectionView layoutIfNeeded];
    [self.collectionView trySetContentOffset:item.offset];
}

@end
