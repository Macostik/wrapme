//
//  GeometryHelper.h
//  meWrap
//
//  Created by Ravenpod on 10/22/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

struct CGLine {
    CGPoint a;
    CGPoint b;
};
typedef struct CGLine CGLine;

static inline CGFloat CGAngleBetweenLines(CGLine l1, CGLine l2) {
    
    CGFloat a = l1.b.x - l1.a.x;
    CGFloat b = l1.b.y - l1.a.y;
    CGFloat c = l2.b.x - l2.a.x;
    CGFloat d = l2.b.y - l2.a.y;
    
    CGFloat s1 = (l1.b.y - l1.a.y) / (l1.b.x - l1.a.x);
    CGFloat s2 = (l2.b.y - l2.a.y) / (l2.b.x - l2.a.x);
    
    CGFloat degs = acosf(((a*c) + (b*d)) / ((sqrt(a*a + b*b)) * (sqrt(c*c + d*d))));
    
    return (s1 > s2) ? degs : -degs;
}

static inline CGFloat CGSizeScaleToFitSize(CGSize sizeToFit, CGSize originalSize) {
    CGFloat horizontalScale = sizeToFit.width / originalSize.width;
    CGFloat verticalScale = sizeToFit.height / originalSize.height;
    return MIN(horizontalScale, verticalScale);
}

static inline CGFloat CGSizeScaleToFillSize(CGSize sizeToFill, CGSize originalSize) {
    CGFloat horizontalScale = sizeToFill.width / originalSize.width;
    CGFloat verticalScale = sizeToFill.height / originalSize.height;
    return MAX(horizontalScale, verticalScale);
}

static inline CGSize CGSizeThatFitsSize(CGSize sizeToFit, CGSize originalSize) {
    CGFloat scale = CGSizeScaleToFitSize(sizeToFit, originalSize);
    return CGSizeMake(originalSize.width * scale, originalSize.height * scale);
}

static inline CGSize CGSizeThatFillsSize(CGSize sizeToFill, CGSize originalSize) {
    CGFloat scale = CGSizeScaleToFillSize(sizeToFill, originalSize);
    return CGSizeMake(originalSize.width * scale, originalSize.height * scale);
}

static inline CGRect CGRectCenteredInSize(CGRect rect, CGSize size) {
    rect.origin = CGPointMake(size.width/2 - rect.size.width/2, size.height/2 - rect.size.height/2);
    return rect;
}

static inline CGRect CGRectThatFitsSize(CGSize sizeToFit, CGSize originalSize) {
    CGRect rect;
    rect.size = CGSizeThatFitsSize(sizeToFit, originalSize);
    return CGRectCenteredInSize(rect, sizeToFit);
}

static inline CGRect CGRectThatFillsSize(CGSize sizeToFill, CGSize originalSize) {
    CGRect rect;
    rect.size = CGSizeThatFillsSize(sizeToFill, originalSize);
    return CGRectCenteredInSize(rect, sizeToFill);
}

static inline CGFloat CGSizeScaleForRotation(CGSize size, CGFloat angle) {
    angle = fabs(angle);
    CGFloat k = size.height/size.width;
    if (size.width > size.height) {
        return fabs(sinf(angle)/k) + fabsf(cosf(angle));
    } else {
        return fabs(k*sinf(angle)) + fabsf(cosf(angle));
    }
}

static inline CGFloat DegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
}

static inline CGFloat RadiansToDegrees(CGFloat radians) {
    return radians * 180 / M_PI;
}

static inline CGFloat CGAffineTransformGetScale(CGAffineTransform t) {
    return sqrtf(powf(t.a, 2) + powf(t.c, 2));
}

static inline CGFloat CGAffineTransformGetAngle(CGAffineTransform t) {
    return atan2(t.b, t.a);
}

static inline CGAffineTransform CGAffineTransformTripleConcat(CGAffineTransform t1, CGAffineTransform t2, CGAffineTransform t3) {
    CGAffineTransform transform = CGAffineTransformConcat(t1, t2);
    return CGAffineTransformConcat(transform, t3);
}

static inline CGRect CGRectStruct(CGPoint origin, CGSize size) {
    return (CGRect){origin, size};
}

static inline CGFloat CGPointDistanceToPoint(CGPoint fromPoint, CGPoint toPoint) {
    CGFloat dx = ABS(toPoint.x - fromPoint.x);
    CGFloat dy = ABS(toPoint.y - fromPoint.y);
    return sqrtf(powf(dx, 2.0f) + powf(dy, 2.0f));
}

static inline CGPoint CGPointOffset(CGPoint point, CGFloat x, CGFloat y) {
    return CGPointMake(point.x + x, point.y + y);
}

static inline CGFloat Smoothstep(CGFloat min, CGFloat max, CGFloat value) {
    if (value < min) return min;
    else if (value > max) return max;
    return value;
}

static inline CGFloat NSmoothstep(CGFloat value) {
    return Smoothstep(0.0, 1.0, value);
}

static inline BOOL IsInBounds(CGFloat min, CGFloat max, CGFloat value) {
    return (value >= min && value <= max);
}

