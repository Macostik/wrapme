//
//  StreamItem.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StreamItem, StreamMetrics, StreamIndex, StreamReusableView;

@protocol StreamItemDelegate <NSObject>

- (void)streamItemWillBecomeInvisible:(StreamItem*)item;

- (void)streamItemWillBecomeVisible:(StreamItem*)item;

@end

@interface StreamItem : NSObject

@property (nonatomic, weak) id <StreamItemDelegate> delegate;

@property (weak, nonatomic) StreamReusableView* view;

@property (nonatomic) CGRect frame;

@property (nonatomic) BOOL visible;

@property (nonatomic) StreamIndex *index;

@property (strong, nonatomic) StreamMetrics *metrics;

@property (nonatomic) BOOL selected;

@end
