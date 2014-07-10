//
//  WLDataStorage.h
//  CoreData
//
//  Created by Sergey Maximenko on 6/12/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLEntry.h"
#import "WLEntry+Extended.h"
#import "WLUser.h"
#import "WLUser+Extended.h"
#import "WLWrap.h"
#import "WLWrap+Extended.h"
#import "WLCandy.h"
#import "WLCandy+Extended.h"
#import "WLComment.h"
#import "WLComment+Extended.h"
#import "WLContribution.h"
#import "WLContribution+Extended.h"
#import "WLUploading.h"
#import "WLUploading+Extended.h"
#import "NSOrderedSet+Additions.h"

@interface WLEntryManager : NSObject

@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSManagedObjectModel *model;
@property (strong, nonatomic) NSPersistentStoreCoordinator *coordinator;

+ (instancetype)manager;

- (void)cacheEntries:(NSOrderedSet*)entries forClass:(Class)entryClass;

- (void)cacheEntry:(WLEntry*)entry;

- (WLEntry*)entryOfClass:(Class)entryClass identifier:(NSString*)identifier;

- (NSOrderedSet*)entriesOfClass:(Class)entryClass;

- (NSOrderedSet*)entriesOfClass:(Class)entryClass configure:(void (^)(NSFetchRequest* request))configure;

- (void)deleteEntry:(WLEntry*)entry;

- (void)save;

@end

@interface WLEntry (WLEntryManager)

@property (readonly, nonatomic) BOOL valid;

+ (NSEntityDescription*)entity;

+ (NSPredicate*)predicate;

+ (NSPredicate*)predicate:(NSString*)identifier;

+ (NSDictionary*)substitutionVariables:(NSString*)identifier;

+ (instancetype)entry:(NSString*)identifier;

+ (NSOrderedSet*)entries;

+ (NSOrderedSet*)entries:(void (^)(NSFetchRequest* request))configure;

- (NSPredicate*)predicate;

- (NSDictionary*)substitutionVariables;

- (void)save;

- (void)remove;

@end
