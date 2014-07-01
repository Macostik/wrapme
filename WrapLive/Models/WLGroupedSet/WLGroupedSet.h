//
//  WLGroupedSet.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLCandy;
@class WLGroup;
@class WLGroupedSet;

@protocol WLGroupedSetDelegate <NSObject>

- (void)groupedSetGroupsChanged:(WLGroupedSet*)set;

@end

@interface WLGroupedSet : NSObject

@property (strong, nonatomic) NSString* dateFormat;

@property (strong, nonatomic) NSMutableOrderedSet *set;

@property (nonatomic, weak) id <WLGroupedSetDelegate> delegate;

- (WLGroup*)groupNamed:(NSString*)name;

- (void)setCandies:(NSOrderedSet*)candies;

- (void)addCandies:(NSOrderedSet*)candies;

- (void)addCandy:(WLCandy*)candy;

- (void)removeCandy:(WLCandy*)candy;

- (void)clear;

- (void)sort:(WLCandy*)candy;

- (void)sort;

@end

@protocol WLGroupDelegate <NSObject>

- (void)groupsChanged:(WLGroup*)group;

@end

@interface WLGroup : NSObject

@property (nonatomic, weak) id <WLGroupDelegate> delegate;

@property (strong, nonatomic) NSString* name;

@property (nonatomic, retain) NSMutableOrderedSet* candies;

@property (nonatomic, weak) WLCandy* message;

+ (instancetype)date;

- (BOOL)addCandies:(NSOrderedSet *)candies;

- (BOOL)addCandy:(WLCandy *)candy;

- (BOOL)addCandies:(NSOrderedSet *)candies sort:(BOOL)sort;

- (BOOL)addCandy:(WLCandy *)candy sort:(BOOL)sort;

- (void)sort;

@end


