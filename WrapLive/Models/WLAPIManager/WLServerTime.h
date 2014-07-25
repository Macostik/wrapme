//
//  WLServerTime.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLServerTime : NSObject

+ (NSTimeInterval)difference;

+ (void)setDifference:(NSTimeInterval)interval;

+ (NSDate*)current;

+ (void)track:(NSDate*)serverTime;

@end

@interface NSDate (WLServerTime)

+ (instancetype)serverTime;

@end
