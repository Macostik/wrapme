//
//  WLCommentCell.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLItemCell.h"

@class WLComment;

static CGFloat WLCommentLabelLenth = 240.0f;
static CGFloat WLAuthorLabelHeight = 14.0f;
static CGFloat WLMinimumCellHeight = 50.0f;

@interface WLCommentCell : WLItemCell

+ (UIFont*)commentFont;

@end
