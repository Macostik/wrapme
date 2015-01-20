//
//  WLCandy.h
//  WrapLive
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WLContribution.h"

@class WLComment, WLWrap, WLUploading;

@interface WLCandy : WLContribution

@property (nonatomic) int16_t type;
@property (nonatomic, retain) WLWrap *wrap;
@property (nonatomic, retain) NSMutableOrderedSet *comments;
@end

@interface WLCandy (CoreDataGeneratedAccessors)

- (void)insertObject:(WLComment *)value inCommentsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCommentsAtIndex:(NSUInteger)idx;
- (void)insertComments:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCommentsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCommentsAtIndex:(NSUInteger)idx withObject:(WLComment *)value;
- (void)replaceCommentsAtIndexes:(NSIndexSet *)indexes withComments:(NSArray *)values;
- (void)addCommentsObject:(WLComment *)value;
- (void)removeCommentsObject:(WLComment *)value;
- (void)addComments:(NSOrderedSet *)values;
- (void)removeComments:(NSOrderedSet *)values;
@end
