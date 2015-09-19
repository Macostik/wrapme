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

static CGFloat WLMessageVerticalInset = 4.0f;
static CGFloat WLMessageHorizontalInset = 6.0f;
static CGFloat WLMessageWithNameMinimumCellHeight = 40.0f;
static CGFloat WLMessageWithoutNameMinimumCellHeight = 24.0f;
static CGFloat WLLeadingBubbleIndent = 64.0f;
static CGFloat WLTrailingBubbleIndent = 16.0f;
static CGFloat WLMessageGroupSpacing = 6.0f;

extern CGFloat WLMaxTextViewWidth;

@interface WLMessageCell : StreamReusableView

@end
