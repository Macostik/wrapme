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

@property (nonatomic, readonly) BOOL isToday;

+ (NSDate *)defaultBirtday;

- (BOOL)isSameDay:(NSDate*)date;

- (NSDate *)beginOfDay;

- (NSDate *)endOfDay;

@end
