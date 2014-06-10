//
//  WLWrap.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapEntry.h"


static NSInteger WLWrapNameLimit = 190;
@class WLCandy;
@class WLUser;
@class WLWrapDate;

@protocol WLUser @end
@protocol WLWrapDate @end

@interface WLWrap : WLWrapEntry

@property (strong, nonatomic) NSArray<WLWrapDate>* dates;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSArray<WLUser>* contributors;

@property (strong, nonatomic) NSString* contributorNames;

- (void)addCandy:(WLCandy*)candy;

- (void)addCandies:(NSArray*)candies;

- (void)addCandies:(NSArray *)candies replaceMessage:(BOOL)replaceMessage;

- (void)removeCandy:(WLCandy*)candy;

- (WLWrapDate*)actualDate;

- (NSArray*)candiesOfType:(NSInteger)type maximumCount:(NSUInteger)maximumCount;

- (NSArray*)candies:(NSUInteger)maximumCount;

- (NSArray*)candies;

- (NSArray*)images:(NSUInteger)maximumCount;

- (NSArray*)messages:(NSUInteger)maximumCount;

- (NSArray*)images;

- (NSArray*)messages;

- (NSArray*)recentCandies:(NSUInteger)maximumCount;

- (void)enumerateCandies:(void (^)(WLCandy* candy, WLWrapDate* date, BOOL *stop))enumerator;

- (BOOL)containsCandy:(WLCandy*)candy;

@end
