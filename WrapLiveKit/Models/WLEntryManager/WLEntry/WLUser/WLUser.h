//
//  WLUser.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/10/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "WLEntry.h"

@class WLContribution, WLDevice, WLWrap;

@interface WLUser : WLEntry

@property (nonatomic) BOOL current;
@property (nonatomic) BOOL firstTimeUse;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSMutableOrderedSet *contributions;
@property (nonatomic, retain) NSMutableOrderedSet *wraps;
@property (nonatomic, retain) NSMutableOrderedSet *devices;
@property (strong, nonatomic) NSString *phones;
@property (strong, nonatomic) NSString *securePhones;

@end

@interface WLUser (CoreDataGeneratedAccessors)

- (void)insertObject:(WLContribution *)value inContributionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromContributionsAtIndex:(NSUInteger)idx;
- (void)insertContributions:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeContributionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInContributionsAtIndex:(NSUInteger)idx withObject:(WLContribution *)value;
- (void)replaceContributionsAtIndexes:(NSIndexSet *)indexes withContributions:(NSArray *)values;
- (void)addContributionsObject:(WLContribution *)value;
- (void)removeContributionsObject:(WLContribution *)value;
- (void)addContributions:(NSOrderedSet *)values;
- (void)removeContributions:(NSOrderedSet *)values;
- (void)insertObject:(WLWrap *)value inWrapsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromWrapsAtIndex:(NSUInteger)idx;
- (void)insertWraps:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeWrapsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInWrapsAtIndex:(NSUInteger)idx withObject:(WLWrap *)value;
- (void)replaceWrapsAtIndexes:(NSIndexSet *)indexes withWraps:(NSArray *)values;
- (void)addWrapsObject:(WLWrap *)value;
- (void)removeWrapsObject:(WLWrap *)value;
- (void)addWraps:(NSOrderedSet *)values;
- (void)removeWraps:(NSOrderedSet *)values;
- (void)addDevicesObject:(WLDevice *)value;
- (void)removeDevicesObject:(WLDevice *)value;
- (void)addDevices:(NSSet *)values;
- (void)removeDevices:(NSSet *)values;

@end