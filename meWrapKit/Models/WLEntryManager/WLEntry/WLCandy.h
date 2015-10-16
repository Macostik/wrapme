//
//  WLCandy.h
//  meWrap
//
//  Created by Ravenpod on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLContribution.h"

static NSInteger WLCandyTypeImage = 10;
static NSInteger WLCandyTypeVideo = 20;

@class WLComment, WLWrap;

@interface WLCandy : WLContribution

@property (nonatomic) int16_t commentCount;
@property (nonatomic) int16_t type;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) WLWrap *wrap;

@property (strong, nonatomic) WLComment *latestComment;

- (NSMutableOrderedSet *)sortedComments;

- (BOOL)isVideo;

@end

@interface WLCandy (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(WLComment *)value;
- (void)removeCommentsObject:(WLComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end
