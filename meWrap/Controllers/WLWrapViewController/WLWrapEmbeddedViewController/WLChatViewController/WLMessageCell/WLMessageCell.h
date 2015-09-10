//
//  WLMessageCell.h
//  meWrap
//
//  Created by Ravenpod on 09.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

static NSString* WLMessageitemIdentifier = @"WLMessageCell";
static NSString* WLMyMessageitemIdentifier = @"WLMyMessageCell";

static CGFloat WLMessageVerticalInset = 6.0f;
static CGFloat WLMessageHorizontalInset = 6.0f;
static CGFloat WLMessageCellBottomConstraint = 14.0f;
static CGFloat WLMessageWithNameMinimumCellHeight = 40.0f;
static CGFloat WLMessageWithoutNameMinimumCellHeight = 24.0f;
static CGFloat WLMessageDayLabelHeight = 34.0f;
static CGFloat WLLeadingIndent = 64.0f;
static CGFloat WLTrailingIndent = 16.0f;
static CGFloat WLMessageGroupSpacing = 14.0f;

extern CGFloat WLMaxTextViewWidth;

@interface WLMessageCell : StreamReusableView

@property (nonatomic) BOOL showName;

@end
