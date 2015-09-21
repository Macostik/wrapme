//
//  StreamCell.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StreamMetrics;
@class StreamItem;

@interface StreamReusableView : UIView

@property (weak, nonatomic) id entry;

@property (weak, nonatomic) StreamMetrics *metrics;

@property (weak, nonatomic) StreamItem *item;

@property (nonatomic) BOOL selected;

- (void)didDequeue;

- (void)willEnqueue;

- (void)setup:(id)entry;

- (void)resetup;

- (void)select:(id)entry;

@end
