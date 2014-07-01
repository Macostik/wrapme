//
//  WLWrapDate.h
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLCandy;

@interface WLDate : NSObject

@property (strong, nonatomic) NSDate* date;

@property (strong, nonatomic) NSString* name;

@property (nonatomic, retain) NSMutableOrderedSet* candies;

@property (nonatomic) BOOL containsMessage;

+ (instancetype)dateWithDate:(NSDate*)date;

+ (NSMutableOrderedSet*)dates:(NSOrderedSet*)entries dates:(NSMutableOrderedSet*)dates;

+ (NSMutableOrderedSet*)dates:(NSOrderedSet*)entries;

- (NSComparisonResult)compare:(WLDate*)date;

- (void)addCandies:(NSOrderedSet *)candies;

- (void)addCandy:(WLCandy *)candy;

- (void)addCandies:(NSOrderedSet *)candies sort:(BOOL)sort;

- (void)addCandy:(WLCandy *)candy sort:(BOOL)sort;

@end

@interface NSMutableOrderedSet (WLDate)

- (void)unionCandies:(NSOrderedSet*)candies;

@end
