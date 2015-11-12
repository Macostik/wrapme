//
//  WLRecentCandiesView.m
//  meWrap
//
//  Created by Ravenpod on 7/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLRecentCandiesView.h"
#import "WLCandyCell.h"

@interface WLRecentCandiesView ()

@property (weak, nonatomic) IBOutlet StreamView *streamView;

@property (strong, nonatomic) StreamDataSource *dataSource;

@end

@implementation WLRecentCandiesView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.dataSource = [[StreamDataSource alloc] initWithStreamView:self.streamView];
    self.dataSource.numberOfGridColumns = 3;
    self.dataSource.sizeForGridColumns = 0.333f;
    self.streamView.layout = [[SquareGridLayout alloc] init];
    [self.dataSource addMetrics:[[StreamMetrics alloc] initWithIdentifier:@"WLCandyCell"]].disableMenu = YES;
    self.dataSource.layoutSpacing = WLConstants.pixelSize;
}

- (void)setup:(Wrap *)wrap {
    [self layoutIfNeeded];
    NSArray *recentCandies = wrap.recentCandies;
    self.dataSource.numberOfItems = @(([recentCandies count] > WLHomeTopWrapCandiesLimit_2) ? WLHomeTopWrapCandiesLimit : WLHomeTopWrapCandiesLimit_2);
    self.dataSource.items = recentCandies;
}

@end
