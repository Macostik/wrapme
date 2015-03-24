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
static CGFloat WLMessageHorizontalInset = 5.0f;
static CGFloat WLMessageCellBottomConstraint = 14.0f;
static CGFloat WLMessageWithNameMinimumCellHeight = 48.0f;
static CGFloat WLMessageWithoutNameMinimumCellHeight = 34.0f;
static CGFloat WLMessageDayLabelHeight = 34.0f;
static CGFloat WLAvatarWidth = 72.0f;
static CGFloat WLAvatarLeading = 12.0f;
static CGFloat WLMinBubbleWidth = 60.0f;
static CGFloat WLMessageGroupSpacing = 14.0f;

extern CGFloat WLMaxTextViewWidth;

@interface WLMessageCell : WLEntryCell

@property (nonatomic) BOOL showDay;

@property (nonatomic) BOOL showName;

- (void)setShowName:(BOOL)showName showDay:(BOOL)showDay;

@end
