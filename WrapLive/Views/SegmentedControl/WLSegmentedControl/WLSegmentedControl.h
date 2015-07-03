//
//  WLSegmentedControl.h
//  WrapLive
//
//  Created by Yura Granchenko on 02/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "SegmentedControl.h"

typedef NS_OPTIONS(NSUInteger, WLSegmentControlState) {
    WLSegmentControlStatePhotos,
    WLSegmentControlStateChat,
    WLSegmentControlStateFriend
};

@interface WLSegmentedControl : SegmentedControl

@end
