//
//  WLNotificationCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLNotificationCell.h"
#import "WLNotification.h"
#import "WLImageFetcher.h"
#import "WLUser+Extended.h"
#import "NSDate+Additions.h"
#import "UILabel+Additions.h"
#import "WLNotification+Extanded.h"

@interface WLNotificationCell ()

@property (weak, nonatomic) IBOutlet WLImageView *pictureView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation WLNotificationCell

- (void)setup:(WLNotification*)notification {
    self.textLabel.text = notification.text;
    [self.textLabel sizeToFitHeightWithMaximumHeightToSuperviewBottom];
    self.pictureView.url = notification.user.picture.small;
    self.userNameLabel.text = notification.user.name;
    self.dateLabel.text = notification.date.timeAgoString;
}

@end
