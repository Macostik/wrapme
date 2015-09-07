//
//  NSDate+PNTimetoken.m
//  meWrap
//
//  Created by Ravenpod on 7/7/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "NSDate+PNTimetoken.h"

static NSTimeInterval PNTimetokenPrecisionMultiplier = 10000000.0f;

@implementation NSDate (PNTimetoken)

+ (instancetype)dateWithTimetoken:(NSNumber*)timetoken {
    return [NSDate dateWithTimeIntervalSince1970:[timetoken doubleValue] / PNTimetokenPrecisionMultiplier];
}

- (NSNumber*)timetoken {
    return @((unsigned long long)([self timeIntervalSince1970] * PNTimetokenPrecisionMultiplier));
}

@end
