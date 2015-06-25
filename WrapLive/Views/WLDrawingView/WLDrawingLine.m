//
//  WLDrawingLine.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDrawingLine.h"
#import "WLDrawingBrush.h"

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

double double_interpolate(double p[], double time[], double t) {
    double L01 = p[0] * (time[1] - t) / (time[1] - time[0]) + p[1] * (t - time[0]) / (time[1] - time[0]);
    double L12 = p[1] * (time[2] - t) / (time[2] - time[1]) + p[2] * (t - time[1]) / (time[2] - time[1]);
    double L23 = p[2] * (time[3] - t) / (time[3] - time[2]) + p[3] * (t - time[2]) / (time[3] - time[2]);
    double L012 = L01 * (time[2] - t) / (time[2] - time[0]) + L12 * (t - time[0]) / (time[2] - time[0]);
    double L123 = L12 * (time[3] - t) / (time[3] - time[1]) + L23 * (t - time[1]) / (time[3] - time[1]);
    double C12 = L012 * (time[2] - t) / (time[2] - time[1]) + L123 * (t - time[1]) / (time[2] - time[1]);
    return C12;
}

NSMutableArray* interpolateStep(NSArray* points, NSInteger index, NSInteger pointsPerSegment) {
    NSMutableArray* result = [NSMutableArray array];
    double x[] = {0,0,0,0};
    double y[] = {0,0,0,0};
    double time[] = {0,0,0,0};
    for (int i = 0; i < 4; i++) {
        CGPoint point = [points[index + i] CGPointValue];
        x[i] = point.x;
        y[i] = point.y;
        time[i] = i;
    }
    
    double tstart = 1;
    double tend = 2;
    
    double total = 0;
    for (int i = 1; i < 4; i++) {
        double dx = x[i] - x[i - 1];
        double dy = y[i] - y[i - 1];
        double dtotal = pow(dx * dx + dy * dy, .25);
        total += dtotal;
        time[i] = total;
    }
    tstart = time[1];
    tend = time[2];
    
    NSInteger segments = pointsPerSegment - 1;
    [result addObject:points[index + 1]];
    for (NSInteger i = 1; i < segments; i++) {
        double xi = double_interpolate(x, time, tstart + (i * (tend - tstart)) / segments);
        double yi = double_interpolate(y, time, tstart + (i * (tend - tstart)) / segments);
        [result addObject:[NSValue valueWithCGPoint:CGPointMake(xi, yi)]];
    }
    [result addObject:points[index + 2]];
    return result;
}

- (NSArray*)interpolatePoints:(NSArray*)currentPoints {
    
    if (currentPoints.count < 3) {
        return currentPoints;
    }
    
    NSInteger segments = 4;
    
    NSMutableArray* points = [currentPoints mutableCopy];
    
    CGPoint point1 = [points[0] CGPointValue];
    CGPoint point2 = [points[1] CGPointValue];
    
    double x1 = 2*point1.x - point2.x;
    double y1 = 2*point1.y - point2.y;
    
    CGPoint start = CGPointMake(x1, y1);
    
    NSInteger n = points.count - 1;
    point1 = [points[n - 1] CGPointValue];
    point2 = [points[n] CGPointValue];
    double xn = 2*point2.x - point1.x;
    double yn = 2*point2.y - point1.y;
    CGPoint end = CGPointMake(xn, yn);
    
    [points insertObject:[NSValue valueWithCGPoint:start] atIndex:0];
    
    [points addObject:[NSValue valueWithCGPoint:end]];
    
    NSMutableArray* result = [NSMutableArray array];
    for (NSInteger i = 0; i < [points count] - 3; i++) {
        NSMutableArray* stepPoints = interpolateStep(points, i, segments);
        if ([result count] > 0) {
            [stepPoints removeObjectAtIndex:0];
        }
        [result addObjectsFromArray:stepPoints];
    }
    return result;
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
    points = [NSMutableArray arrayWithArray:[self interpolatePoints:points]];
    [self.path removeAllPoints];
    if (points.nonempty) {
        if (points.count == 1) {
            [self.path moveToPoint:[points[0] CGPointValue]];
            [self.path addLineToPoint:[points[0] CGPointValue]];
        } else {
            for (NSValue *point in points) {
                if (point == points.firstObject) {
                    [self.path moveToPoint:[point CGPointValue]];
                } else {
                    [self.path addLineToPoint:[point CGPointValue]];
                }
            }
        }
    }
}

- (void)render {
    [[self.brush.color colorWithAlphaComponent:self.brush.opacity] setStroke];
    [self.path stroke];
}

@end
