//
//  WLWrapCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntryCell.h"

static NSUInteger WLHomeTopWrapCandiesLimit = 6;
static NSUInteger WLHomeTopWrapCandiesLimit_2 = 3;

@class WLWrapCell;
@class WLCandy;
@class WLWrap;
@class SegmentedControl;

@interface WLWrapCell : WLEntryCell

@property (weak, nonatomic, readonly) UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet SegmentedControl *tabControl;

@property (weak, nonatomic) IBOutlet UIImageView *liveNotifyBulb;

- (void)setCandies:(NSMutableOrderedSet *)candies;

@end
