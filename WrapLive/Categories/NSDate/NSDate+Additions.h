//
//  NSDate+Additions.h
//  WrapLive
//
//  Created by Sergey Maximenko on 05.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Additions)

@property (readonly, nonatomic) NSString* timeAgoString;

@property (readonly, nonatomic) NSString* timeAgoStringAtAMPM;

@property (nonatomic, readonly) BOOL isToday;

@property (readonly, nonatomic) NSTimeInterval timestamp;

+ (NSDate *)defaultBirtday;

+ (NSDate *)sinceWeekAgo;

+ (NSDate *)dayAgo;

- (NSDateComponents *)dayComponents;

- (BOOL)isSameDay:(NSDate*)date;

- (BOOL)isSameDayComponents:(NSDateComponents *)c;

- (BOOL)isSameHour:(NSDate*)date;

- (NSDate *)beginOfDay;

- (NSDate *)endOfDay;

- (void)getBeginOfDay:(NSDate**)beginOfDay endOfDay:(NSDate**)endOfDay;

- (BOOL)earlier:(NSDate*)date;

- (BOOL)later:(NSDate*)date;

- (BOOL)match:(NSDate*)date;

@end
