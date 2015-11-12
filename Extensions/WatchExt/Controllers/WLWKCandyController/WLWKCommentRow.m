//
//  WLCommentRow.m
//  meWrap
//
//  Created by Ravenpod on 2/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKCommentRow.h"
#import "WKInterfaceImage+WLImageFetcher.h"

@interface WLWKCommentRow ()

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *avatar;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *contributorNameLabel;

@end

@implementation WLWKCommentRow

- (void)setEntry:(Comment *)comment {
    [super setEntry:comment];
    self.avatar.url = comment.contributor.picture.small;
    [self.contributorNameLabel setText:comment.contributor.name];
    [self.text setText:comment.text];
    [self.dateLabel setText:[comment.createdAt timeAgoStringAtAMPM]];
}

@end
