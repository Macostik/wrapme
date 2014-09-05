//
//  WLTimelineViewSection.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCollectionViewDataProvider.h"

@class WLTimeline;

@interface WLTimelineViewDataProvider : WLCollectionViewDataProvider

@property (strong, nonatomic) WLTimeline* timeline;

@property (strong, nonatomic) WLObjectBlock selection;

@end
