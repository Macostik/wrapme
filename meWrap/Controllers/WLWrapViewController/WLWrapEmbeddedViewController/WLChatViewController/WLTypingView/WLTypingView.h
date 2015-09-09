//
//  WLTypingView.h
//  meWrap
//
//  Created by Yura Granchenko on 10/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"
#import "WLChat.h"

static CGFloat WLTypingViewMinHeight = 56.0;
static CGFloat WLTypingViewTopIndent = 8.0;
static NSString *WLFriendsTypingImage = @"friends";

@interface WLTypingView : StreamReusableView

- (void)updateWithChat:(WLChat *)chat;

@end
