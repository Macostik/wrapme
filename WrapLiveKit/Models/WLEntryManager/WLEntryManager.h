//
//  WLDataStorage.h
//  CoreData
//
//  Created by Sergey Maximenko on 6/12/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLEntry+Extended.h"
#import "WLUser+Extended.h"
#import "WLDevice+Extended.h"
#import "WLWrap+Extended.h"
#import "WLCandy+Extended.h"
#import "WLComment+Extended.h"
#import "WLContribution+Extended.h"
#import "WLUploading+Extended.h"
#import "WLMessage+Extended.h"
#import "NSOrderedSet+Additions.h"

@interface WLEntryManager : NSObject

@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSManagedObjectModel *model;
@property (strong, nonatomic) NSPersistentStoreCoordinator *coordinator;

+ (instancetype)manager;

- (void)cacheEntry:(WLEntry*)entry;

- (void)uncacheEntry:(WLEntry*)entry;

- (WLEntry*)entryOfClass:(Class)entryClass identifier:(NSString*)identifier;

- (WLEntry*)entryOfClass:(Class)entryClass identifier:(NSString*)identifier uploadIdentifier:(NSString*)uploadIdentifier;

- (BOOL)entryExists:(Class)entryClass identifier:(NSString*)identifier;

- (NSMutableOrderedSet*)entriesOfClass:(Class)entryClass;

- (NSMutableOrderedSet*)entriesOfClass:(Class)entryClass configure:(void (^)(NSFetchRequest* request))configure;

- (void)deleteEntry:(WLEntry*)entry;

- (void)save;

- (NSArray*)executeFetchRequest:(NSFetchRequest*)request;

- (void)clear;

@end

@interface WLEntry (WLEntryManager)

@property (readonly, nonatomic) BOOL valid;

@property (readonly, nonatomic) BOOL invalid;

+ (NSEntityDescription *)entity;

+ (instancetype)entry:(NSString*)identifier;

+ (NSMutableOrderedSet *)entries;

+ (NSMutableOrderedSet *)entries:(void (^)(NSFetchRequest* request))configure;

+ (NSMutableOrderedSet *)entriesWithPredicate:(NSPredicate*)predicate;

+ (NSMutableOrderedSet *)entriesWhere:(NSString *)predicateFormat, ...;

+ (NSMutableOrderedSet *)entriesSortedBy:(NSString*)key where:(NSString *)predicateFormat, ...;

+ (NSMutableOrderedSet *)entriesSortedBy:(NSString*)key ascending:(BOOL)ascending where:(NSString *)predicateFormat, ...;

+ (BOOL)entryExists:(NSString*)identifier;

+ (Class)entryClassByName:(NSString*)entryName;

- (void)save;

- (void)remove;

@end

@interface NSFetchRequest (WLEntryManager)

- (NSArray*)execute;

@end
