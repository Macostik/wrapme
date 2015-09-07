//
//  WLRecentCandiesView.h
//  meWrap
//
//  Created by Ravenpod on 7/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

@class StreamDataSource, StreamView;

static NSUInteger WLHomeTopWrapCandiesLimit = 6;
static NSUInteger WLHomeTopWrapCandiesLimit_2 = 3;

@interface WLRecentCandiesView : StreamReusableView

@property (weak, nonatomic, readonly) StreamView *streamView;

@property (strong, nonatomic, readonly) StreamDataSource* dataSource;

@end
