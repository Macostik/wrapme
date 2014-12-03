//
//  WLExtensionCell.m
//  WrapLive
//
//  Created by Yura Granchenko on 11/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLExtensionCell.h"
#import "NSDate+Additions.h"

@interface WLExtensionCell ()

@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UILabel *eventLabel;
@property (weak, nonatomic) IBOutlet UILabel *wrapNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

@implementation WLExtensionCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    self =  [super initWithCoder:aDecoder];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    return self;
}

- (void)setAttEntry:(NSDictionary *)attEntry {
    WLPost *entry = [WLPost initWithAttributes:attEntry];
    
    self.coverImageView.image = [UIImage imageWithData:entry.image];
    self.eventLabel.text = entry.event;
    self.wrapNameLabel.text = entry.wrapName;
    self.timeLabel.text = [entry.time timeAgoString];
}

@end