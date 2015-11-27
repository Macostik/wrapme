//
//  WLWKPostRow.m
//  meWrap
//
//  Created by Ravenpod on 1/16/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKEntryRow.h"
#import "WKInterfaceImage+WLImageFetcher.h"

@implementation WLWKEntryRow

@end

@interface WLWKCommentEventRow ()

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *mainGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *avatar;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *photoByLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *wrapNameLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;

@end

@implementation WLWKCommentEventRow

- (void)setEntry:(Comment *)entry {
    self.avatar.url = entry.contributor.picture.small;
    self.mainGroup.url = entry.candy.picture.small;
    [self.photoByLabel setText:[NSString stringWithFormat:(entry.candy.isVideo ? @"formatted_video_by" : @"formatted_photo_by").ls, entry.candy.contributor.name]];
    [self.wrapNameLabel setText:entry.candy.wrap.name];
    [self.text setText:[NSString stringWithFormat:@"\"%@\"", entry.text]];
    [self.dateLabel setText:entry.createdAt.timeAgoStringAtAMPM];
}

@end

@interface WLWKCandyEventRow ()

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *dataGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *photoByLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *wrapNameLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;

@end

@implementation WLWKCandyEventRow

- (void)setEntry:(Candy *)entry {
    [self.photoByLabel setText:[NSString stringWithFormat:(entry.isVideo ? @"formatted_video_by" : @"formatted_photo_by").ls, entry.contributor.name]];
    [self.wrapNameLabel setText:entry.wrap.name];
    [self.dateLabel setText:[entry.createdAt timeAgoStringAtAMPM]];
    self.group.url = entry.picture.small;
}

@end
