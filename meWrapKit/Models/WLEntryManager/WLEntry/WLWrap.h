//
//  WLWrap.h
//  meWrap
//
//  Created by Ravenpod on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLContribution.h"

@class WLCandy, WLMessage, WLUser;

@interface WLWrap : WLContribution

@property (nonatomic) BOOL isCandyNotifiable;
@property (nonatomic) BOOL isChatNotifiable;
@property (nonatomic) BOOL isRestrictedInvite;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *candies;
@property (nonatomic, retain) NSSet *contributors;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic) BOOL isPublic;

@property (nonatomic, retain) WLCandy *cover;

@property (nonatomic, retain) NSMutableOrderedSet *recentCandies;

@property (nonatomic, readonly) BOOL isFirstCreated;

@property (readonly, nonatomic) BOOL requiresFollowing;

@property (readonly, nonatomic) BOOL isContributing;

- (NSString*)contributorNames;

- (BOOL)isFirstCreated;

@end

@interface WLWrap (CoreDataGeneratedAccessors)

- (void)addCandiesObject:(WLCandy *)value;
- (void)removeCandiesObject:(WLCandy *)value;
- (void)addCandies:(NSSet *)values;
- (void)removeCandies:(NSSet *)values;

- (void)addContributorsObject:(WLUser *)value;
- (void)removeContributorsObject:(WLUser *)value;
- (void)addContributors:(NSSet *)values;
- (void)removeContributors:(NSSet *)values;

- (void)addMessagesObject:(WLMessage *)value;
- (void)removeMessagesObject:(WLMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
