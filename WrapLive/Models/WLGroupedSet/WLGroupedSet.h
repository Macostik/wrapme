//
//  WLGroupedSet.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLPaginatedSet.h"

@class WLCandy;
@class WLGroup;
@class WLGroupedSet;

@protocol WLGroupedSetDelegate <NSObject>

- (void)groupedSetGroupsChanged:(WLGroupedSet*)set;

@end

@interface WLGroupedSet : NSObject

@property (strong, nonatomic) NSString* dateFormat;

@property (nonatomic) BOOL singleMessage;

@property (strong, nonatomic) NSMutableOrderedSet *set;

@property (nonatomic, weak) id <WLGroupedSetDelegate> delegate;

- (WLGroup*)group:(NSDate*)date;

- (void)setCandies:(NSOrderedSet*)candies;

- (void)addCandies:(NSOrderedSet*)candies;

- (void)addCandy:(WLCandy*)candy;

- (void)addCandy:(WLCandy *)candy created:(BOOL *)created;

- (void)removeCandy:(WLCandy*)candy;

- (void)clear;

- (void)sort:(WLCandy*)candy;

- (void)sort;

@end

@interface WLGroup : WLPaginatedSet

@property (nonatomic) BOOL singleMessage;

@property (strong, nonatomic) NSString* name;

@property (strong, nonatomic) NSDate* date;

@property (nonatomic, weak) WLCandy* message;

@property (nonatomic) CGPoint offset;

+ (instancetype)date;

- (BOOL)hasAtLeastOneImage;

@end


