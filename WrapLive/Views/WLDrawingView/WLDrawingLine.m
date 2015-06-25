//
//  WLDrawingLine.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDrawingLine.h"
#import "WLDrawingBrush.h"
#import "UIBezierPath+Interpolation.h"

@interface WLDrawingLine ()

@end

@implementation WLDrawingLine

- (instancetype)init {
    self = [super init];
    if (self) {
        self.path = [UIBezierPath bezierPath];
        self.path.lineCapStyle = kCGLineCapRound;
        self.path.lineJoinStyle = kCGLineJoinRound;
    }
    return self;
}

- (void)setBrush:(WLDrawingBrush *)brush {
    _brush = [brush copy];
    self.path.lineWidth = brush.width;
}

- (void)addPoint:(CGPoint)point {
    if (!self.completed) {
        if (self.path.empty) {
            [self.path moveToPoint:point];
            [self.path addLineToPoint:point];
        } else {
            if (!CGPointEqualToPoint(self.path.currentPoint, point)) {
                [self.path addLineToPoint:point];
            }
        }
    }
}

void CGPathApplierFunc (void *info, const CGPathElement *element) {
    NSMutableArray *bezierPoints = (__bridge NSMutableArray *)info;
    
    CGPoint *points = element->points;
    CGPathElementType type = element->type;
    
    switch(type) {
        case kCGPathElementMoveToPoint: // contains 1 point
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            break;
            
        case kCGPathElementAddLineToPoint: // contains 1 point
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            break;
            
        case kCGPathElementAddQuadCurveToPoint: // contains 2 points
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[1]]];
            break;
            
        case kCGPathElementAddCurveToPoint: // contains 3 points
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[1]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[2]]];
            break;
            
        case kCGPathElementCloseSubpath: // contains no point
            break;
    }
}

- (void)interpolate {
    NSMutableArray *points = [NSMutableArray array];
    CGPathApply(self.path.CGPath, (__bridge void *)(points), CGPathApplierFunc);
    __block CGPoint p;
    points = [points map:^id(NSValue *point) {
        BOOL remove = CGPointEqualToPoint(p, [point CGPointValue]);
        p = [point CGPointValue];
        return remove ? nil : point;
    }];
    
    if (points.count > 2) {
        UIBezierPath *path = [UIBezierPath interpolateCGPointsWithHermite:points closed:NO];
        path.lineCapStyle = self.path.lineCapStyle;
        path.lineJoinStyle = self.path.lineJoinStyle;
        path.lineWidth = self.path.lineWidth;
        self.path = path;
    }
}

- (void)render {
    [[self.brush.color colorWithAlphaComponent:self.brush.opacity] setStroke];
    [self.path stroke];
}

- (BOOL)intersectsRect:(CGRect)rect {
    return CGRectIntersectsRect(self.path.bounds, rect);
}

@end
