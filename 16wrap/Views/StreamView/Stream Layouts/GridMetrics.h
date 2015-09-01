//
//  GridMetrics.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamMetrics.h"

@interface GridMetrics : StreamMetrics

@property (nonatomic) IBInspectable CGFloat ratio;

@property (strong, nonatomic) CGFloat(^ratioBlock)(StreamIndex *index, StreamMetrics *metrics);

- (void)setRatioBlock:(CGFloat (^)(StreamIndex *index, StreamMetrics *metrics))ratioBlock;

- (CGFloat)ratioAt:(StreamIndex*)index;

@end
