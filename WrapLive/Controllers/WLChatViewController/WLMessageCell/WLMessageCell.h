//
//  WLMessageCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntryCell.h"

static CGFloat WLNameLabelHeight = 5.0f;
static CGFloat WLMessageAuthorLabelHeight = 21.0f;
static CGFloat WLMessageMinimumCellHeight = 60.0f;
static CGFloat WLLastMessageMinimumCellHeight = 40.0f;
static CGFloat WLAvatarWidth = 66.0f;
static CGFloat WLEmptyCellHeight = 66.0f;
static CGFloat WLMinBubbleWidth = 15.0f;
static CGFloat WLBottomIdent = 12.0f;
static CGFloat WLPadding = 20.0f;
extern CGFloat WLMaxTextViewWidth;

@interface WLMessageCell : WLEntryCell

@property (nonatomic) BOOL showDay;

@end
