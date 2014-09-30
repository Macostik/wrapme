//
//  WLTimelineEventCommentCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTimelineEventCommentCell.h"
#import "WLImageView.h"
#import "WLComment.h"
#import "NSString+Additions.h"
#import "WLEntryManager.h"

@interface WLTimelineEventCommentCell ()

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation WLTimelineEventCommentCell

- (void)setup:(WLComment*)comment {
    self.imageView.url = comment.picture.small;
    self.textLabel.text = [NSString stringWithFormat:@"\"%@\"", comment.text];
    if (comment.valid) {
        if (!NSNumberEqual(comment.unread, @NO)) comment.unread = @NO;
    }
}

@end
