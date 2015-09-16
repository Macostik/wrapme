//
//  WLRecentCandiesView.m
//  meWrap
//
//  Created by Ravenpod on 7/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLRecentCandiesView.h"
#import "StreamDataSource.h"
#import "WLCandyCell.h"

@interface WLRecentCandiesView ()

@property (weak, nonatomic) IBOutlet StreamView *streamView;

@property (strong, nonatomic) StreamDataSource *dataSource;

@end

@implementation WLRecentCandiesView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.dataSource = [StreamDataSource dataSourceWithStreamView:self.streamView];
    self.dataSource.numberOfGridColumns = 3;
    self.dataSource.sizeForGridColumns = 0.333f;
    self.streamView.layout = [[SquareGridLayout alloc] init];
    [self.dataSource addMetrics:[[StreamMetrics alloc] initWithIdentifier:@"WLCandyCell"]];
    [self.dataSource setNumberOfItemsBlock:^NSUInteger (StreamDataSource *dataSource) {
        return ([dataSource.items count] > WLHomeTopWrapCandiesLimit_2) ? WLHomeTopWrapCandiesLimit : WLHomeTopWrapCandiesLimit_2;
    }];
    self.dataSource.layoutSpacing = WLConstants.pixelSize;
}

- (void)setup:(WLWrap*)wrap {
    [self layoutIfNeeded];
    self.dataSource.items = wrap.recentCandies;
}

@end
