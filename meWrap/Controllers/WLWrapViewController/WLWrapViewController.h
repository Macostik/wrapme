//
//  WLWrapViewController.h
//  meWrap
//
//  Created by Ravenpod on 20.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class Wrap, LiveBroadcast;

typedef NS_OPTIONS(NSUInteger, WLWrapSegment) {
    WLWrapSegmentMedia,
    WLWrapSegmentChat,
    WLWrapSegmentFriend
};

@interface WLWrapViewController : WLBaseViewController

@property (weak, nonatomic) Wrap *wrap;

@property (nonatomic) WLWrapSegment segment;

@property (nonatomic) BOOL showKeyboard;

- (void)presentLiveProadcast:(LiveBroadcast*)broadcast;

@end
