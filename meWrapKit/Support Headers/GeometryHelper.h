//
//  GeometryHelper.h
//  meWrap
//
//  Created by Ravenpod on 10/22/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

static inline CGSize CGSizeThatFitsSize(CGSize size, CGSize original) {
    CGFloat scale = MIN(size.width / original.width, size.height / original.height);
    return CGSizeMake(original.width * scale, original.height * scale);
}

static inline CGSize CGSizeThatFillsSize(CGSize size, CGSize original) {
    CGFloat scale = MAX(size.width / original.width, size.height / original.height);
    return CGSizeMake(original.width * scale, original.height * scale);
}

static inline CGRect CGRectCenteredInSize(CGRect rect, CGSize size) {
    rect.origin = CGPointMake(size.width/2 - rect.size.width/2, size.height/2 - rect.size.height/2);
    return rect;
}

static inline CGRect CGRectThatFitsSize(CGSize size, CGSize original) {
    CGRect rect;
    rect.size = CGSizeThatFitsSize(size, original);
    return CGRectCenteredInSize(rect, size);
}

static inline CGRect CGRectThatFillsSize(CGSize size, CGSize original) {
    CGRect rect;
    rect.size = CGSizeThatFillsSize(size, original);
    return CGRectCenteredInSize(rect, size);
}

static inline CGFloat DegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
}

static inline CGFloat RadiansToDegrees(CGFloat radians) {
    return radians * 180 / M_PI;
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

