//
//  WLTimelineHeaderView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/27/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTimelineEventHeaderView.h"
#import "WLImageView.h"
#import "WLTimelineEvent.h"
#import "NSDate+Formatting.h"
#import "WLUser.h"

@interface WLTimelineEventHeaderView ()

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation WLTimelineEventHeaderView

- (void)setEvent:(WLTimelineEvent *)event {
    _event = event;
    self.dateLabel.text = [event.date stringWithFormat:@"h:mm aa"];
    self.avatarView.url = event.user.picture.small;
    self.textLabel.text = event.text;
}

@end
