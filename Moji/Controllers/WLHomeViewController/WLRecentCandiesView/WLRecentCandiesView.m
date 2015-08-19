//
//  WLRecentCandiesView.m
//  moji
//
//  Created by Ravenpod on 7/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLRecentCandiesView.h"
#import "StreamDataSource.h"
#import "WLCandyCell.h"
#import "GridMetrics.h"

@interface WLRecentCandiesView ()

@property (weak, nonatomic) IBOutlet StreamView *streamView;

@property (strong, nonatomic) IBOutlet StreamDataSource *dataSource;

@end

@implementation WLRecentCandiesView

- (void)awakeFromNib {
    [super awakeFromNib];
    
//    dataSource.minimumLineSpacing = WLCandyCellSpacing;
//    dataSource.sectionLeftInset = dataSource.sectionRightInset = WLCandyCellSpacing;
    [self.dataSource setNumberOfItemsBlock:^NSUInteger (StreamDataSource *dataSource) {
        return ([dataSource.items count] > WLHomeTopWrapCandiesLimit_2) ? WLHomeTopWrapCandiesLimit : WLHomeTopWrapCandiesLimit_2;
    }];
    [[(GridMetrics*)self.dataSource.metrics ratio] setBlock:^CGFloat(StreamIndex *index) {
        return 1;
    }];
}

- (void)setup:(WLWrap*)wrap {
    self.dataSource.items = [[NSMutableOrderedSet orderedSetWithSet:wrap.candies] sortByUpdatedAt];
}

@end
