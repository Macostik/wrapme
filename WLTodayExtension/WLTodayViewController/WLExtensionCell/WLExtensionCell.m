//
//  WLExtensionCell.m
//  WrapLive
//
//  Created by Yura Granchenko on 11/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLExtensionCell.h"

@interface WLExtensionCell ()

@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UILabel *eventLabel;
@property (weak, nonatomic) IBOutlet UILabel *wrapNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;

@end

@implementation WLExtensionCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    self =  [super initWithCoder:aDecoder];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    return self;
}

- (void)setPost:(WLPost *)post {
    self.coverImageView.image = [UIImage imageWithData:post.image];
    self.eventLabel.text = post.event;
    self.wrapNameLabel.text = post.wrapName;
    [self.wrapNameLabel sizeToFit];
    self.widthConstraint.constant = self.wrapNameLabel.bounds.size.width;
    [self.timeLabel setNeedsLayout];
    self.timeLabel.text = [post.time timeAgoStringAtAMPM];
}

@end