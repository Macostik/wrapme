//
//  WLEntry.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLArchivingObject.h"
#import "WLPicture.h"
#import "NSArray+Additions.h"

@interface WLEntry : WLArchivingObject

@property (strong, nonatomic) WLPicture* picture;
@property (strong, nonatomic) NSDate* createdAt;
@property (strong, nonatomic) NSDate *updatedAt;
@property (strong, nonatomic) NSString* identifier;

+ (instancetype)entry;

+ (NSDictionary*)pictureMapping;

- (BOOL)isEqualToEntry:(WLEntry*)entry;

+ (EqualityBlock)equalityBlock;

@end

@interface NSArray (WLEntry)

- (NSArray*)entriesSortedByKeys:(NSArray*)keys ascending:(BOOL)ascending;

- (NSArray*)entriesSortedByKey:(NSString*)key ascending:(BOOL)ascending;

- (NSArray*)entriesSortedByKey:(NSString*)key;

- (NSArray*)entriesSortedByUpdatingDate;

- (NSArray *)entriesByAddingEntry:(WLEntry*)entry;

- (NSArray *)entriesByInsertingEntry:(WLEntry*)entry atIndex:(NSUInteger)index;

- (NSArray *)entriesByInsertingFirstEntry:(WLEntry*)entry;

- (NSArray *)entriesByRemovingEntry:(WLEntry*)entry;

- (BOOL)containsEntry:(WLEntry*)entry;

- (NSArray *)entriesByAddingEntries:(NSArray*)entries;

- (NSArray *)entriesByInsertingEntries:(NSArray*)entries atIndex:(NSUInteger)index;

- (NSArray *)entriesByInsertingFirstEntries:(NSArray*)entries;

- (NSArray *)entriesByRemovingEntries:(NSArray*)entries;

- (NSArray *)entriesFrom:(NSDate *)from to:(NSDate*)to;

- (NSArray *)entriesForDay:(NSDate *)date;

- (NSArray *)entriesForToday;

@end

@interface NSMutableArray (WLEntry)

- (void)sortEntriesByKeys:(NSArray *)keys ascending:(BOOL)ascending;

- (void)sortEntriesByKey:(NSString*)key ascending:(BOOL)ascending;

- (void)sortEntriesByKey:(NSString*)key;

- (void)sortEntriesByUpdatingDate;

- (void)addEntry:(WLEntry*)entry;

- (void)insertEntry:(WLEntry*)entry atIndex:(NSUInteger)index;

- (void)insertFirstEntry:(WLEntry*)entry;

- (void)removeEntry:(WLEntry*)entry;

- (void)addEntries:(NSArray*)entries;

- (void)insertEntries:(NSArray*)entries atIndex:(NSUInteger)index;

- (void)insertFirstEntries:(NSArray*)entries;

- (void)removeEntries:(NSArray*)entries;

@end
