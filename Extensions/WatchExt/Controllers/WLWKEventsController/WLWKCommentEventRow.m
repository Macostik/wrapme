//
//  WLWKCommentRowType.m
//  meWrap
//
//  Created by Ravenpod on 12/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWKCommentEventRow.h"
#import "WLComment.h"
#import "WLUser.h"
#import "WLCandy.h"
#import "WLWrap.h"
#import "NSDate+Additions.h"
#import "WKInterfaceImage+WLImageFetcher.h"

@interface WLWKCommentEventRow ()

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *mainGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *avatar;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *photoByLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *wrapNameLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;

@end

@implementation WLWKCommentEventRow

- (void)setEntry:(WLComment *)entry {
    self.avatar.url = entry.contributor.picture.small;
    self.mainGroup.url = entry.candy.picture.small;
    [self.photoByLabel setText:[NSString stringWithFormat:[entry.candy messageAppearanceByCandyType:@"formatted_video_by"
                                                                                                and:@"formatted_photo_by"], entry.candy.contributor.name]];
    [self.wrapNameLabel setText:entry.candy.wrap.name];
    [self.text setText:[NSString stringWithFormat:@"\"%@\"", entry.text]];
    [self.dateLabel setText:entry.createdAt.timeAgoStringAtAMPM];
}

@end
