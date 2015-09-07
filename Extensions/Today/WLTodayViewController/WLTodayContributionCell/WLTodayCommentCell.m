//
//  WLTodayCommentCell.m
//  meWrap
//
//  Created by Ravenpod on 3/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLTodayCommentCell.h"

@interface WLTodayCommentCell ()

@end

@implementation WLTodayCommentCell

- (void)setContribution:(WLComment *)comment {
    [super setContribution:comment];
    self.pictureView.url = comment.picture.small;
    self.wrapNameLabel.text = comment.candy.wrap.name;
    self.descriptionLabel.text = [NSString stringWithFormat:@"%@ commented \"%@\"", comment.contributor.name, comment.text];
}

@end
