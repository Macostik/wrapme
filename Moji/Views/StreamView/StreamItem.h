//
//  StreamItem.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StreamMetrics, StreamIndex, StreamReusableView;

@interface StreamItem : NSObject

@property (weak, nonatomic) StreamReusableView* view;

@property (nonatomic) CGRect frame;

@property (nonatomic) BOOL visible;

@property (nonatomic) StreamIndex *index;

@property (strong, nonatomic) StreamMetrics *metrics;

@property (nonatomic) BOOL selected;

@end
