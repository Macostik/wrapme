//
//  NSDate+Additions.h
//  WrapLive
//
//  Created by Sergey Maximenko on 05.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

static const NSTimeInterval WLTimeIntervalMinute = 60;
static const NSTimeInterval WLTimeIntervalHour = 3600;
static const NSTimeInterval WLTimeIntervalDay = 86400;
static const NSTimeInterval WLTimeIntervalWeek = 604800;

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

- (NSComparisonResult)timestampCompare:(NSDate*)date;

@end
