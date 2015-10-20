//
//  WLRecentCandiesView.h
//  meWrap
//
//  Created by Ravenpod on 7/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

@class StreamDataSource, StreamView;

@interface WLRecentCandiesView : StreamReusableView

@property (weak, nonatomic, readonly) StreamView *streamView;

@property (strong, nonatomic, readonly) StreamDataSource* dataSource;

@end
