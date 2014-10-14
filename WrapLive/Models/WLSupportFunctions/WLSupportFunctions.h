//
//  WLSupportFunctions.h
//  WrapLive
//
//  Created by Sergey Maximenko on 17.01.14.
//

#import <Foundation/Foundation.h>

typedef void (^timecost_block)(void);

NS_INLINE NSTimeInterval timecost(timecost_block block) {
    NSDate* date = [NSDate date];
    block();
    return -[date timeIntervalSinceNow];
}

NS_INLINE NSTimeInterval iteratedTimecost(NSUInteger i, timecost_block block) {
    NSTimeInterval t = 0;
    while (i) {
        t += timecost(block);
        --i;
    }
    return t;
}

NS_INLINE NSArray* timecosts(timecost_block block, ...) {
    va_list args;
    va_start(args, block);
    NSMutableArray* array = [NSMutableArray array];
    for (; block != nil; block = va_arg(args, id)) {
        [array addObject:@(timecost(block))];
    }
    va_end(args);
    return array;
}

NS_INLINE NSArray* iteratedTimecosts(NSUInteger i, timecost_block block, ...) {
    va_list args;
    va_start(args, block);
    NSMutableArray* array = [NSMutableArray array];
    for (; block != nil; block = va_arg(args, id)) {
        [array addObject:@(iteratedTimecost(i, block))];
    }
    va_end(args);
    return array;
}

NS_INLINE void logTimecost(timecost_block block) {
    NSLog(@"\n\ntimecost %f\n", timecost(block));
}

NS_INLINE void logIteratedTimecost(NSUInteger i, timecost_block block) {
    NSLog(@"\n\ntimecost %f\n", iteratedTimecost(i, block));
}

#define logTimecosts(block, ...) NSLog(@"\n\ntimecost = %@\n", timecosts(block, __VA_ARGS__, nil))

#define logIteratedTimecosts(i, block, ...) NSLog(@"\n\ntimecost = %@\n", iteratedTimecosts(i, block, __VA_ARGS__, nil))

struct CGLine {
    CGPoint a;
    CGPoint b;
};
typedef struct CGLine CGLine;

NS_INLINE CGFloat CGAngleBetweenLines(CGLine l1, CGLine l2) {
    
    CGFloat a = l1.b.x - l1.a.x;
    CGFloat b = l1.b.y - l1.a.y;
    CGFloat c = l2.b.x - l2.a.x;
    CGFloat d = l2.b.y - l2.a.y;
    
    CGFloat s1 = (l1.b.y - l1.a.y) / (l1.b.x - l1.a.x);
    CGFloat s2 = (l2.b.y - l2.a.y) / (l2.b.x - l2.a.x);
    
    CGFloat degs = acosf(((a*c) + (b*d)) / ((sqrt(a*a + b*b)) * (sqrt(c*c + d*d))));
    
    return (s1 > s2) ? degs : -degs;
}

NS_INLINE CGSize CGRetinaSize(CGSize size) {
    return CGSizeMake(size.width*2, size.height*2);
}

NS_INLINE CGSize CGSizeThatFitsSize(CGSize sizeToFit, CGSize originalSize) {
    CGFloat horizontalScale = sizeToFit.width / originalSize.width;
    CGFloat verticalScale = sizeToFit.height / originalSize.height;
    
    CGFloat scale = MIN(horizontalScale, verticalScale);
    
    return CGSizeMake(originalSize.width * scale, originalSize.height * scale);
}

NS_INLINE CGSize CGSizeThatFillsSize(CGSize sizeToFill, CGSize originalSize) {
    CGFloat horizontalScale = sizeToFill.width / originalSize.width;
    CGFloat verticalScale = sizeToFill.height / originalSize.height;
    
    CGFloat scale = MAX(horizontalScale, verticalScale);
    
    return CGSizeMake(originalSize.width * scale, originalSize.height * scale);
}

NS_INLINE CGRect CGRectCenteredInSize(CGRect rect, CGSize size) {
    rect.origin = CGPointMake(size.width/2 - rect.size.width/2, size.height/2 - rect.size.height/2);
    return rect;
}

NS_INLINE CGRect CGRectThatFitsSize(CGSize sizeToFit, CGSize originalSize) {
    CGRect rect;
    rect.size = CGSizeThatFitsSize(sizeToFit, originalSize);
    return CGRectCenteredInSize(rect, sizeToFit);
}

NS_INLINE CGRect CGRectThatFillsSize(CGSize sizeToFill, CGSize originalSize) {
    CGRect rect;
    rect.size = CGSizeThatFillsSize(sizeToFill, originalSize);
    return CGRectCenteredInSize(rect, sizeToFill);
}

NS_INLINE CGFloat CGSizeScaleForRotation(CGSize size, CGFloat angle) {
    angle = fabsf(angle);
    CGFloat k = size.height/size.width;
    if (size.width > size.height) {
        return fabsf(sinf(angle)/k) + fabsf(cosf(angle));
    } else {
        return fabsf(k*sinf(angle)) + fabsf(cosf(angle));
    }
}

NS_INLINE CGFloat DegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
}

NS_INLINE CGFloat RadiansToDegrees(CGFloat radians) {
    return radians * 180 / M_PI;
}

NS_INLINE CGFloat CGAffineTransformGetScale(CGAffineTransform t) {
    return sqrtf(powf(t.a, 2) + powf(t.c, 2));
}

NS_INLINE CGFloat CGAffineTransformGetAngle(CGAffineTransform t) {
    return atan2(t.b, t.a);
}

NS_INLINE CGAffineTransform CGAffineTransformTripleConcat(CGAffineTransform t1, CGAffineTransform t2, CGAffineTransform t3) {
    CGAffineTransform transform = CGAffineTransformConcat(t1, t2);
    return CGAffineTransformConcat(transform, t3);
}

NS_INLINE CGRect CGRectStruct(CGPoint origin, CGSize size) {
    return (CGRect){origin, size};
}

NS_INLINE CGFloat CGPointDistanceToPoint(CGPoint fromPoint, CGPoint toPoint) {
    CGFloat dx = ABS(toPoint.x - fromPoint.x);
    CGFloat dy = ABS(toPoint.y - fromPoint.y);
    return sqrtf(powf(dx, 2.0f) + powf(dy, 2.0f));
}

NS_INLINE CGFloat Smoothstep(CGFloat min, CGFloat max, CGFloat value) {
	if (value < min) return min;
	else if (value > max) return max;
	return value;
}

NS_INLINE BOOL IsInBounds(CGFloat min, CGFloat max, CGFloat value) {
	return (value >= min && value <= max);
}
