//
//  WLTypingView.h
//  WrapLive
//
//  Created by Yura Granchenko on 10/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLUser.h"

static CGFloat WLTypingViewMinHeight = 20.0f;

@interface WLTypingViewCell : UICollectionReusableView

- (void)setNames:(NSString *)names;

@end
