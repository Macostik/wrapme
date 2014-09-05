//
//  PGSupportFunctions.m
//  Pressgram
//
//  Created by Sergey Maximenko on 17.01.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import "WLSupportFunctions.h"

void logTimecost(NSString* key, int iterations, timecost_block block) {
    int i = iterations;
    NSTimeInterval t = CFAbsoluteTimeGetCurrent();
    while (i) {
        block();
        --i;
    }
    t = CFAbsoluteTimeGetCurrent() - t;
    NSLog(@"%@ %f",key,t);
}

NSTimeInterval timecost(timecost_block block) {
    NSDate* date = [NSDate date];
    block();
    return -[date timeIntervalSinceNow];
}

CGFloat CGAngleBetweenLines(CGLine l1, CGLine l2) {
    
    CGFloat a = l1.b.x - l1.a.x;
    CGFloat b = l1.b.y - l1.a.y;
    CGFloat c = l2.b.x - l2.a.x;
    CGFloat d = l2.b.y - l2.a.y;
    
    CGFloat s1 = (l1.b.y - l1.a.y) / (l1.b.x - l1.a.x);
    CGFloat s2 = (l2.b.y - l2.a.y) / (l2.b.x - l2.a.x);
    
    CGFloat degs = acosf(((a*c) + (b*d)) / ((sqrt(a*a + b*b)) * (sqrt(c*c + d*d))));
    
    return (s1 > s2) ? degs : -degs;
}

CGSize CGRetinaSize(CGSize size) {
    return CGSizeMake(size.width*2, size.height*2);
}

CGSize CGSizeThatFitsSize(CGSize sizeToFit, CGSize originalSize) {
    CGFloat horizontalScale = sizeToFit.width / originalSize.width;
    CGFloat verticalScale = sizeToFit.height / originalSize.height;
    
    CGFloat scale = MIN(horizontalScale, verticalScale);
    
    return CGSizeMake(originalSize.width * scale, originalSize.height * scale);
}

CGSize CGSizeThatFillsSize(CGSize sizeToFill, CGSize originalSize) {
    CGFloat horizontalScale = sizeToFill.width / originalSize.width;
    CGFloat verticalScale = sizeToFill.height / originalSize.height;
    
    CGFloat scale = MAX(horizontalScale, verticalScale);
    
    return CGSizeMake(originalSize.width * scale, originalSize.height * scale);
}

CGRect CGRectCenteredInSize(CGRect rect, CGSize size) {
    rect.origin = CGPointMake(size.width/2 - rect.size.width/2, size.height/2 - rect.size.height/2);
    return rect;
}

CGRect CGRectThatFitsSize(CGSize sizeToFit, CGSize originalSize) {
    CGRect rect;
    rect.size = CGSizeThatFitsSize(sizeToFit, originalSize);
    return CGRectCenteredInSize(rect, sizeToFit);
}

CGRect CGRectThatFillsSize(CGSize sizeToFill, CGSize originalSize) {
    CGRect rect;
    rect.size = CGSizeThatFillsSize(sizeToFill, originalSize);
    return CGRectCenteredInSize(rect, sizeToFill);
}

CGFloat CGSizeScaleForRotation(CGSize size, CGFloat angle) {
    angle = fabsf(angle);
    
    CGFloat k = size.height/size.width;
    
    if (size.width > size.height) {
        return fabsf(sinf(angle)/k) + fabsf(cosf(angle));
    } else {
        return fabsf(k*sinf(angle)) + fabsf(cosf(angle));
    }
}

CGFloat DegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
};

CGFloat RadiansToDegrees(CGFloat radians)
{
    return radians * 180 / M_PI;
};

CGFloat CGAffineTransformGetScale(CGAffineTransform t) {
    return sqrtf(powf(t.a, 2) + powf(t.c, 2));
}

CGFloat CGAffineTransformGetAngle(CGAffineTransform t) {
    return atan2(t.b, t.a);
}

CGAffineTransform CGAffineTransformTripleConcat(CGAffineTransform t1, CGAffineTransform t2, CGAffineTransform t3) {
    CGAffineTransform transform = CGAffineTransformConcat(t1, t2);
    return CGAffineTransformConcat(transform, t3);
}

CGRect CGRectStruct(CGPoint origin, CGSize size) {
    return (CGRect){origin, size};
}

CGFloat CGPointDistanceToPoint(CGPoint fromPoint, CGPoint toPoint) {
    CGFloat dx = ABS(toPoint.x - fromPoint.x);
    CGFloat dy = ABS(toPoint.y - fromPoint.y);
    return sqrtf(powf(dx, 2.0f) + powf(dy, 2.0f));
}
