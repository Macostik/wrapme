//
//  WLCommentCell.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/28/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLItemCell.h"

@class WLComment;
@class WLCandy;
@class WLWrap;

static CGFloat WLCommentLabelLenth = 250.0f;
static CGFloat WLAuthorLabelHeight = 20.0f;
static CGFloat WLMinimumCellHeight = 50.0f;

@interface WLCommentCell : WLItemCell

@property (weak, nonatomic) WLWrap* wrap;

@property (weak, nonatomic) WLCandy* candy;

+ (UIFont*)commentFont;

@end
