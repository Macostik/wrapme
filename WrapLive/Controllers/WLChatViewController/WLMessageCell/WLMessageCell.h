//
//  WLMessageCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntryCell.h"

static NSString* WLMessageCellIdentifier = @"WLMessageCell";
static NSString* WLMyMessageCellIdentifier = @"WLMyMessageCell";

static CGFloat WLMessageNameInset = 18.0f;
static CGFloat WLMessageVerticalInset = 5.0f;
static CGFloat WLMessageHorizontalInset = 3.0f;
static CGFloat WLMessageCellBottomConstraint = 14.0f;
static CGFloat WLMessageMinimumCellHeight = 48.0f;
static CGFloat WLAvatarWidth = 66.0f;
static CGFloat WLMinBubbleWidth = 37.0f;

extern CGFloat WLMaxTextViewWidth;

@interface WLMessageCell : WLEntryCell

@property (nonatomic) BOOL showDay;

@property (nonatomic) BOOL showName;

@property (nonatomic) BOOL showAvatar;

@end
