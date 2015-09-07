//
//  WLWrapCandiesCell.h
//  meWrap
//
//  Created by Ravenpod on 26.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"
#import "WLHistoryItemDataSource.h"

@interface WLCandiesCell : StreamReusableView

@property (strong, nonatomic, readonly) WLHistoryItemDataSource* dataSource;

@property (weak, nonatomic, readonly) StreamMetrics *candyMetrics;

@end