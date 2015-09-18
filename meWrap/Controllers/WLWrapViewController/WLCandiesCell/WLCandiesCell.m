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
#import "WLChronologicalEntryPresenter.h"

@interface WLCandiesCell ()

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (strong, nonatomic) IBOutlet WLHistoryItemDataSource* dataSource;

@property (weak, nonatomic) IBOutlet StreamMetrics *candyMetrics;

@end

@implementation WLCandiesCell

- (void)awakeFromNib {
	[super awakeFromNib];
    self.dataSource.streamView.layout = [[SquareGridLayout alloc] initWithHorizontal:YES];
    self.candyMetrics = [self.dataSource addMetrics:[[StreamMetrics alloc] initWithIdentifier:@"WLCandyCell"]];
    self.dataSource.layoutSpacing = WLConstants.pixelSize;
}

- (void)setup:(WLHistoryItem*)item {
    [self layoutIfNeeded];
    self.dataSource.items = item;
    [self.dataSource.streamView trySetContentOffset:item.offset];
	self.dateLabel.text = [item.date stringWithDateStyle:NSDateFormatterMediumStyle];
}

@end
