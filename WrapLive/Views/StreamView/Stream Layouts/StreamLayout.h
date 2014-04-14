//
//  PICStreamLayout.h
//  RIOT
//
//  Created by Sergey Maximenko on 09.10.13.
//  Copyright (c) 2013 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamView.h"

@class StreamLayoutItem;

@interface StreamLayout : NSObject

@property (nonatomic, weak) StreamView* streamView;

@property (nonatomic) NSInteger numberOfColumns;

@property (nonatomic) CGFloat* ranges;

@property (nonatomic) CGFloat* sizes;

- (NSSet*)layoutItems:(NSUInteger)numberOfItems ratio:(CGFloat (^)(StreamLayoutItem* item, NSUInteger itemIndex))ratio;

- (CGRect)frameForItemWithRatio:(CGFloat)ratio;

@property (nonatomic, readonly) CGSize contentSize;

- (void)setSize:(CGFloat)size;

- (void)setSize:(CGFloat)size atIndex:(NSInteger)index;

- (CGFloat)offset:(NSInteger)column;

- (void)setRange:(CGFloat)range;

- (void)setRange:(CGFloat)range atIndex:(NSInteger)index;

- (void)updateRange:(CGFloat)range;

- (CGFloat)minimumRange:(NSInteger*)column;

- (CGFloat)maximumRange:(NSInteger*)column;

@end

CGRect CGRectScale(CGRect rect, CGFloat xScale, CGFloat yScale);
