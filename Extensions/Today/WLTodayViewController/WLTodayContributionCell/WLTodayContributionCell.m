//
//  WLTodayContributionCell.m
//  meWrap
//
//  Created by Ravenpod on 3/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLTodayContributionCell.h"

@interface WLTodayContributionCell ()

@end

@implementation WLTodayContributionCell

- (void)setContribution:(Contribution *)contribution {
    _contribution = contribution;
    self.timeLabel.text = [contribution.createdAt timeAgoStringAtAMPM];
}

@end
