//
//  WLMessageCell.h
//  moji
//
//  Created by Ravenpod on 09.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

static NSString* WLMessageitemIdentifier = @"WLMessageCell";
static NSString* WLMyMessageitemIdentifier = @"WLMyMessageCell";

static CGFloat WLMessageVerticalInset = 5.0f;
static CGFloat WLMessageHorizontalInset = 5.0f;
static CGFloat WLMessageCellBottomConstraint = 14.0f;
static CGFloat WLMessageWithNameMinimumCellHeight = 48.0f;
static CGFloat WLMessageWithoutNameMinimumCellHeight = 34.0f;
static CGFloat WLMessageDayLabelHeight = 34.0f;
static CGFloat WLAvatarWidth = 72.0f;
static CGFloat WLAvatarLeading = 12.0f;
static CGFloat WLMessageGroupSpacing = 14.0f;

extern CGFloat WLMaxTextViewWidth;

@interface WLMessageCell : StreamReusableView

@property (nonatomic) BOOL showName;

@end
