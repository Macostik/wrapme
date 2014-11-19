//
//  WLTimelineEventCommentCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTimelineEventCell.h"

@interface WLTimelineEventCommentCell : WLTimelineEventCell

+ (CGFloat)heightWithComments:(NSOrderedSet*)comments;

@end
