//
//  WLWrap.h
//  WrapLive
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WLContribution.h"

@class WLCandy, WLUser;

@interface WLWrap : WLContribution

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSMutableOrderedSet *candies;
@property (nonatomic, retain) NSMutableOrderedSet *contributors;
@property (strong, nonatomic) NSArray* invitees;
@end

@interface WLWrap (CoreDataGeneratedAccessors)

- (void)insertObject:(WLCandy *)value inCandiesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCandiesAtIndex:(NSUInteger)idx;
- (void)insertCandies:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCandiesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCandiesAtIndex:(NSUInteger)idx withObject:(WLCandy *)value;
- (void)replaceCandiesAtIndexes:(NSIndexSet *)indexes withCandies:(NSArray *)values;
- (void)addCandiesObject:(WLCandy *)value;
- (void)removeCandiesObject:(WLCandy *)value;
- (void)addCandies:(NSOrderedSet *)values;
- (void)removeCandies:(NSOrderedSet *)values;
- (void)insertObject:(WLUser *)value inContributorsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromContributorsAtIndex:(NSUInteger)idx;
- (void)insertContributors:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeContributorsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInContributorsAtIndex:(NSUInteger)idx withObject:(WLUser *)value;
- (void)replaceContributorsAtIndexes:(NSIndexSet *)indexes withContributors:(NSArray *)values;
- (void)addContributorsObject:(WLUser *)value;
- (void)removeContributorsObject:(WLUser *)value;
- (void)addContributors:(NSOrderedSet *)values;
- (void)removeContributors:(NSOrderedSet *)values;
@end
