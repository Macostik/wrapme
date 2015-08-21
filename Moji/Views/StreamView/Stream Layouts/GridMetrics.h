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

@property (strong, nonatomic) CGFloat(^ratioBlock)(StreamIndex *index);

- (CGFloat)ratioAt:(StreamIndex*)index;

@end
