//
//  WLTodayContributionCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 3/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLTodayContributionCell : UITableViewCell

@property (weak, nonatomic) WLContribution *contribution;

@property (weak, nonatomic) IBOutlet WLImageView *pictureView;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UILabel *wrapNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end
