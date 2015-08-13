//
//  WLWKCandyRow.m
//  moji
//
//  Created by Ravenpod on 1/16/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKCandyEventRow.h"
#import "WKInterfaceImage+WLImageFetcher.h"

@interface WLWKCandyEventRow () <WLImageFetching>

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *dataGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *photoByLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *wrapNameLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;

@end

@implementation WLWKCandyEventRow

- (void)setEntry:(WLCandy *)entry {
    [self.photoByLabel setText:[NSString stringWithFormat:WLLS(@"formatted_photo_by"), entry.contributor.name]];
    [self.wrapNameLabel setText:entry.wrap.name];
    [self.dateLabel setText:[entry.createdAt timeAgoStringAtAMPM]];
    self.group.url = entry.picture.small;
}

@end
