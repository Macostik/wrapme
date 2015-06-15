//
//  WLTapBarStoryboardTransition.h
//  WrapLive
//
//  Created by Yura Granchenko on 11/06/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStoryboardTransition.h"
#import "SegmentedControl.h"

typedef NS_OPTIONS(NSUInteger, WLSegmentControlState) {
    WLSegmentControlStatePhotos,
    WLSegmentControlStateChat,
    WLSegmentControlStateFriend 
 
};

@interface WLTapBarStoryboardTransition : WLStoryboardTransition

- (IBAction)addChild:(id)sender;

@end

