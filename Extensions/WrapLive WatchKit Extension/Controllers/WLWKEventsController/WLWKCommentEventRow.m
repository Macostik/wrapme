//
//  WLWKCommentRowType.m
//  WrapLive
//
//  Created by Sergey Maximenko on 12/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWKCommentEventRow.h"
#import "WLComment+Extended.h"
#import "WLUser+Extended.h"
#import "WLCandy+Extended.h"
#import "WLWrap+Extended.h"
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
    [self.photoByLabel setText:[NSString stringWithFormat:WLLS(@"formatted_photo_by"), entry.candy.contributor.name]];
    [self.wrapNameLabel setText:entry.candy.wrap.name];
    [self.text setText:[NSString stringWithFormat:@"\"%@\"", entry.text]];
    [self.dateLabel setText:entry.createdAt.timeAgoStringAtAMPM.stringByCapitalizingFirstCharacter];
}

@end
