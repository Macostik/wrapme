//
//  WLTodayContributionCell.h
//  meWrap
//
//  Created by Ravenpod on 3/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLImageView.h"

@interface WLTodayContributionCell : UITableViewCell

@property (weak, nonatomic) WLContribution *contribution;

@property (weak, nonatomic) IBOutlet WLImageView *pictureView;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UILabel *wrapNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end
