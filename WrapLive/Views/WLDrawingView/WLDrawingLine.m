//
//  WLDrawingLine.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDrawingLine.h"
#import "WLDrawingBrush.h"

@implementation WLDrawingLine

- (instancetype)init {
    self = [super init];
    if (self) {
        self.points = [NSMutableArray array];
    }
    return self;
}

- (void)addPoint:(CGPoint)point {
    [self.points addObject:[NSValue valueWithCGPoint:point]];
}

- (void)render:(BOOL)approximated {
    WLDrawingBrush *brush = self.brush;
    [[brush.color colorWithAlphaComponent:brush.opacity] setStroke];
    UIBezierPath *path = [UIBezierPath bezierPath];
    NSArray *points = self.points;
    for (NSValue *point in points) {
        if (point == points.firstObject) {
            [path moveToPoint:[point CGPointValue]];
            if (points.count == 1) {
                [path addLineToPoint:[point CGPointValue]];
            }
        } else {
            [path addLineToPoint:[point CGPointValue]];
        }
    }
    path.lineWidth = brush.width;
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;
    [path stroke];
}

@end
