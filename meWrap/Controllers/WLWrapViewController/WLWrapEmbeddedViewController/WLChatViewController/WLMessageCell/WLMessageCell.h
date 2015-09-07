//
//  WLMessageCell.h
//  meWrap
//
//  Created by Ravenpod on 09.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntryCell.h"

static NSString* WLMessageCellIdentifier = @"WLMessageCell";
static NSString* WLMyMessageCellIdentifier = @"WLMyMessageCell";

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

@interface WLMessageCell : WLEntryCell

@property (nonatomic) BOOL showName;

@end
