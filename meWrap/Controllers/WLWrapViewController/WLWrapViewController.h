//
//  WLWrapViewController.h
//  meWrap
//
//  Created by Ravenpod on 20.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

typedef NS_OPTIONS(NSUInteger, WLWrapSegment) {
    WLWrapSegmentPhotos,
    WLWrapSegmentChat,
    WLWrapSegmentFriend
};

@interface WLWrapViewController : WLBaseViewController

@property (weak, nonatomic) WLWrap* wrap;

@property (nonatomic) WLWrapSegment segment;

@property (nonatomic) BOOL showKeyboard;

@end
