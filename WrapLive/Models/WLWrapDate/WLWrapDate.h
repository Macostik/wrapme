//
//  WLWrapDay.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/27/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"

@class WLCandy;

@protocol WLCandy @end

@interface WLWrapDate : WLEntry

@property (strong, nonatomic) NSArray<WLCandy> *candies;

+ (NSArray*)datesWithCandies:(NSArray*)candies;

- (void)addCandy:(WLCandy *)candy;

- (void)addCandy:(WLCandy *)candy replaceMessage:(BOOL)replaceMessage;

- (void)removeCandy:(WLCandy *)candy;

- (NSArray *)candiesOfType:(NSInteger)type maximumCount:(NSUInteger)maximumCount;

- (NSArray *)candies:(NSUInteger)maximumCount;

- (NSArray*)images:(NSUInteger)maximumCount;

- (NSArray*)messages:(NSUInteger)maximumCount;

- (NSArray*)images;

- (NSArray*)messages;

@end
