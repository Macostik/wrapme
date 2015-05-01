//
//  WLTodayContributionCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 3/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLTodayContributionCell.h"

@interface WLTodayContributionCell ()

@end

@implementation WLTodayContributionCell

- (void)setContribution:(WLContribution *)contribution {
    _contribution = contribution;
    self.timeLabel.text = [contribution.createdAt timeAgoStringAtAMPM];
}

@end
