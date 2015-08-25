//
//  WLWrapCandiesCell.m
//  moji
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
@property (weak, nonatomic) IBOutlet StreamView *streamView;

@property (strong, nonatomic) IBOutlet WLHistoryItemDataSource* dataSource;

@end

@implementation WLCandiesCell

- (void)awakeFromNib {
	[super awakeFromNib];
    self.dataSource.layoutSpacing = WLConstants.pixelSize;
}

- (void)setup:(WLHistoryItem*)item {
    self.dataSource.items = item;
	self.dateLabel.text = [item.date stringWithDateStyle:NSDateFormatterMediumStyle];
    [self.streamView trySetContentOffset:item.offset];
}

@end
