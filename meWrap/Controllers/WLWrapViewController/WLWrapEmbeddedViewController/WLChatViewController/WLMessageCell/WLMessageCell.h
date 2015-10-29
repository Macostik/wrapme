//
//  WLMessageCell.h
//  meWrap
//
//  Created by Ravenpod on 09.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

static CGFloat WLMessageVerticalInset = 6.0f;
static CGFloat WLMessageHorizontalInset = 6.0f;
static CGFloat WLMessageWithNameMinimumCellHeight = 40.0f;
static CGFloat WLMessageWithoutNameMinimumCellHeight = 24.0f;
static CGFloat WLLeadingBubbleIndentWithAvatar = 64.0f;
static CGFloat WLBubbleIndent = 16.0f;
static CGFloat WLMessageGroupSpacing = 6.0f;
static CGFloat WLNameVerticalInset = 4.0;

extern CGFloat WLMaxTextViewWidth;
extern CGFloat WLMinTextViewWidth;

@interface WLMessageCell : StreamReusableView

@property (weak, nonatomic) IBOutlet UIImageView *tailView;

@end
