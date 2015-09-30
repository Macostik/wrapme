//
//  WLDataStorage.h
//  CoreData
//
//  Created by Ravenpod on 6/12/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLEntry+Extended.h"
#import "WLUser+Extended.h"
#import "WLDevice+Extended.h"
#import "WLWrap+Extended.h"
#import "WLCandy+Extended.h"
#import "WLComment+Extended.h"
#import "WLContribution+Extended.h"
#import "WLMessage+Extended.h"
#import "WLCollections.h"
#import "WLEntryDescriptor.h"

typedef void (^WLEntryManagerBackgroundContextBlock) (id *result, NSError **error, NSManagedObjectContext *backgroundContext);

typedef void (^WLEntryManagerMainContextSuccessBlock) (id result, NSManagedObjectContext *mainContext);

typedef void (^WLEntryManagerMainContextFailureBlock) (NSError *error, NSManagedObjectContext *mainContext);

@interface WLEntryManager : NSObject

@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSManagedObjectContext *backgroundContext;
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

- (void)fetchEntries:(NSArray *)descriptors;

- (void)deleteEntry:(WLEntry*)entry;

- (void)save;

- (NSArray*)executeFetchRequest:(NSFetchRequest*)request;

- (void)assureSave:(WLBlock)block;

- (void)performBlockInBackground:(WLEntryManagerBackgroundContextBlock)block success:(WLEntryManagerMainContextSuccessBlock)success failure:(WLEntryManagerMainContextFailureBlock)failure;

- (void)executeFetchRequest:(NSFetchRequest*)request success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (void)countForFetchRequest:(NSFetchRequest*)request success:(void (^)(NSUInteger))success failure:(WLFailureBlock)failure;

- (void)clear;

@end

@interface WLEntry (WLEntryManager)

@property (readonly, nonatomic) BOOL valid;

@property (readonly, nonatomic) BOOL invalid;

+ (NSEntityDescription *)entity;

+ (instancetype)entry:(NSString*)identifier;

+ (NSArray *)entries;

+ (NSArray *)entriesWithPredicate:(NSPredicate*)predicate;

+ (NSArray *)entriesWhere:(NSString *)predicateFormat, ...;

+ (NSFetchRequest*)fetchRequest;

+ (NSFetchRequest*)fetchRequest:(NSString *)predicateFormat, ...;

+ (NSFetchRequest*)fetchRequestWithPredicate:(NSPredicate*)predicate;

+ (void)entries:(WLArrayBlock)success failure:(WLFailureBlock)failure;

+ (void)entriesWithPredicate:(NSPredicate*)predicate success:(WLArrayBlock)success failure:(WLFailureBlock)failure;

+ (BOOL)entryExists:(NSString*)identifier;

- (void)save;

- (void)remove;

@end

@interface NSFetchRequest (WLEntryManager)

- (NSArray*)execute;

- (NSArray*)executeInContext:(NSManagedObjectContext*)context;

- (void)execute:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (void)count:(void (^)(NSUInteger))success failure:(WLFailureBlock)failure;

- (instancetype)sortedBy:(NSString*)sortedBy;

- (instancetype)sortedBy:(NSString*)sortedBy ascending:(BOOL)ascending;

- (instancetype)limitedTo:(NSUInteger)limitedTo;

- (instancetype)groupedBy:(NSArray *)propertiesToGroupBy fetch:(NSArray*)propertiesToFetch;

@end
