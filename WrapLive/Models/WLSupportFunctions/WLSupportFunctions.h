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

CGFloat CGAngleBetweenLines(CGLine l1, CGLine l2);

CGSize CGRetinaSize(CGSize size);
CGSize CGSizeThatFitsSize(CGSize sizeToFit, CGSize originalSize);
CGSize CGSizeThatFillsSize(CGSize sizeToFill, CGSize originalSize);
CGRect CGRectCenteredInSize(CGRect rect, CGSize size);
CGRect CGRectThatFitsSize(CGSize sizeToFit, CGSize originalSize);
CGRect CGRectThatFillsSize(CGSize sizeToFill, CGSize originalSize);
CGFloat DegreesToRadians(CGFloat degrees);
CGFloat RadiansToDegrees(CGFloat radians);

CGFloat CGSizeScaleForRotation(CGSize size, CGFloat angle);

CGFloat CGAffineTransformGetScale(CGAffineTransform t);
CGFloat CGAffineTransformGetAngle(CGAffineTransform t);
CGAffineTransform CGAffineTransformTripleConcat(CGAffineTransform t1, CGAffineTransform t2, CGAffineTransform t3);

CGRect CGRectStruct(CGPoint origin, CGSize size);

CGFloat CGPointDistanceToPoint(CGPoint fromPoint, CGPoint toPoint);

static inline CGFloat Smoothstep(CGFloat min, CGFloat max, CGFloat value) {
	if (value < min) {
		return min;
	} else if (value > max) {
		return max;
	}
	return value;
}

static inline BOOL IsInBounds(CGFloat min, CGFloat max, CGFloat value) {
	return (value >= min && value <= max);
}
