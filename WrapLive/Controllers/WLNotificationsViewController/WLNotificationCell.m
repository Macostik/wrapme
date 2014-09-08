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
#import "WLEntryManager.h"

@interface WLNotificationCell ()

@property (weak, nonatomic) IBOutlet WLImageView *pictureView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *inWrapLabel;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet WLImageView *wrapImageView;

@end

@implementation WLNotificationCell

- (void)setup:(WLComment*)comment {
    [self.textLabel sizeToFitHeightWithMaximumHeightToSuperviewBottom];
    self.pictureView.url = comment.contributor.picture.small;
    self.wrapImageView.url = comment.candy.picture.small;
    self.userNameLabel.text = [NSString stringWithFormat:@"%@  %@",comment.contributor.name, comment.createdAt.timeAgoString];
    self.textLabel.text = [NSString stringWithFormat:@"\"%@\"", comment.text];
    self.inWrapLabel.text = [NSString stringWithFormat:@"in Wrap : @\"%@\"", comment.candy.wrap.name];
}

@end
