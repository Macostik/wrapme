//
//  WLRecentCandiesView.h
//  moji
//
//  Created by Ravenpod on 7/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntryReusableView.h"

@class WLBasicDataSource;

static NSUInteger WLHomeTopWrapCandiesLimit = 6;
static NSUInteger WLHomeTopWrapCandiesLimit_2 = 3;

@interface WLRecentCandiesView : WLEntryReusableView

@property (weak, nonatomic, readonly) UICollectionView *collectionView;

@property (strong, nonatomic, readonly) WLBasicDataSource* dataSource;

@end
