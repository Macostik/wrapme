//
//  WLTypingView.h
//  WrapLive
//
//  Created by Yura Granchenko on 10/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

static CGFloat WLTypingViewMinHeight = 48.0;
static NSString *WLFriendsTypingImage = @"friends";

@interface WLTypingViewCell : UICollectionReusableView

- (void)setNames:(NSString *)names;
- (void)setAvatar:(NSString *)url;

@end
