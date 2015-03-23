//
//  WLCommentRow.m
//  WrapLive
//
//  Created by Sergey Maximenko on 2/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKCommentRow.h"
#import "WLComment+Extended.h"
#import "WLUser+Extended.h"
#import "WLWKImageCache.h"
#import "NSDate+Additions.h"

@interface WLWKCommentRow ()

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *contributorName;

@property (strong, nonatomic) IBOutlet WKInterfaceImage *contributorImage;

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;

@end

@implementation WLWKCommentRow

- (void)setEntry:(WLComment *)comment {
    __weak typeof(self)weakSelf = self;
    [WLWKImageCache imageWithURL:comment.contributor.picture.small edit:^UIImage *(UIImage *image) {
        return [image circleImage];
    } completion:^(UIImage *image) {
        [weakSelf.contributorImage setImage:image];
    }];
    [self.contributorName setText:comment.contributor.name];
    [self.text setText:comment.text];
    [self.dateLabel setText:[comment.createdAt timeAgoStringAtAMPM]];
}

@end
