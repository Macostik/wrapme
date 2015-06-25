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

@property (strong, nonatomic) UIBezierPath* path;

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

double interpolate_step(double p0, double p1, double t0, double t1, double t) {
    //    p1 * (p2 - p3) / (p2 - p4) + p5 * (p3 - p4) / (p2 - p4)
    //    p[0] * (time[1] - t) / (time[1] - time[0]) + p[1] * (t - time[0]) / (time[1] - time[0]);
    return p0 * (t1 - t) / (t1 - t0) + p1 * (t - t0) / (t1 - t0);
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
    
    //
    
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
    
    //
    
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
    
    NSInteger segments = 20;
    
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

- (void)interpolate {
//    self.points = [NSMutableArray arrayWithArray:[self interpolatePoints:self.points]];
}

- (void)render {
    [[self.brush.color colorWithAlphaComponent:self.brush.opacity] setStroke];
    [self.path stroke];
}

- (void)setCompleted:(BOOL)completed {
    _completed = completed;
//    UIBezierPath *path = [UIBezierPath bezierPath];
//    NSArray *points = self.points;
//    for (NSValue *point in points) {
//        if (point == points.firstObject) {
//            [path moveToPoint:[point CGPointValue]];
//            if (points.count == 1) {
//                [path addLineToPoint:[point CGPointValue]];
//            }
//        } else {
//            [path addLineToPoint:[point CGPointValue]];
//        }
//    }
//    path.lineWidth = self.brush.width;
//    path.lineCapStyle = kCGLineCapRound;
//    path.lineJoinStyle = kCGLineJoinRound;
//    self.path = path;
}

@end
