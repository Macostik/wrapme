//
//  WLTimeline.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedSet.h"

@interface WLTimeline : WLPaginatedSet

@property (weak, nonatomic) WLWrap* wrap;

@property (strong, nonatomic) NSMutableOrderedSet* images;

+ (instancetype)timelineWithWrap:(WLWrap*)wrap;

- (void)update;

@end
