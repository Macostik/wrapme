//
//  WLSupportFunctions.h
//  WrapLive
//
//  Created by Sergey Maximenko on 17.01.14.
//

#import <Foundation/Foundation.h>

typedef void (^timecost_block)(void);

void logTimecost(NSString* key, int iterations, timecost_block block);
NSTimeInterval timecost(timecost_block block);

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

CGFloat Smoothstep(CGFloat min, CGFloat max, CGFloat value);

CGFloat CGPointDistanceToPoint(CGPoint fromPoint, CGPoint toPoint);

