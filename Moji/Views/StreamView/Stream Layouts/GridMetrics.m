//
//  GridMetrics.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "GridMetrics.h"

@implementation GridMetrics

- (CGFloat)ratioAt:(StreamIndex *)index {
    return self.ratioBlock ? self.ratioBlock(index) : self.ratio;
}

@end
