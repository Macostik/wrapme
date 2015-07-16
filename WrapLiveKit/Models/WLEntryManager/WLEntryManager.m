//
//  WLDataStorage.m
//  CoreData
//
//  Created by Sergey Maximenko on 6/12/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntryManager.h"
#import "NSString+Additions.h"
#import <objc/runtime.h>
#import "WLAPIRequest.h"
#import "NSUserDefaults+WLAppGroup.h"
#import "WLEntryNotifier.h"

@interface WLMergePolicy : NSMergePolicy

@end

@implementation WLMergePolicy

- (BOOL)resolveConflicts:(NSArray *)list error:(NSError *__autoreleasing *)error {
    [super resolveConflicts:list error:error];
    return YES;
}

@end

@interface WLEntryManager ()

@property (strong, nonatomic) NSMapTable* cachedEntries;

@property (strong, nonatomic) NSMutableSet *assureSaveBlocks;

@end

@implementation WLEntryManager

+ (instancetype)manager {
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.assureSaveBlocks = [NSMutableSet set];
        self.cachedEntries = [NSMapTable strongToWeakObjectsMapTable];
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(save) name:UIApplicationWillTerminateNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(save) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(save) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (NSManagedObjectContext *)context {
    if (_context != nil) {
        return _context;
    }
    [NSValueTransformer setValueTransformer:[[WLPictureTransformer alloc] init] forName:@"pictureTransformer"];
    NSPersistentStoreCoordinator *coordinator = [self coordinator];
    if (coordinator != nil) {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_context setPersistentStoreCoordinator:coordinator];
        _context.mergePolicy = [[WLMergePolicy alloc] initWithMergeType:NSOverwriteMergePolicyType];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:NSManagedObjectContextObjectsDidChangeNotification object:_context];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:_context];
    }
    return _context;
}

- (void)didSaveNotification:(NSNotification*)notification {
    if (notification.object == self.context) {
        [self.backgroundContext mergeChangesFromContextDidSaveNotification:notification];
    }
}

- (NSManagedObjectModel *)model {
    if (_model != nil) {
        return _model;
    }
    NSURL *url = [self modelURL];
    _model = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
    return _model;
}

- (NSURL*)modelURL {
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url = [bundle URLForResource:@"CoreData" withExtension:@"momd"];
    if (!url) {
        for (NSBundle *bundle in [NSBundle allBundles]) {
            url = [bundle URLForResource:@"CoreData" withExtension:@"momd"];
            if (url) {
                break;
            }
        }
    }
    return url;
}

- (NSPersistentStoreCoordinator *)coordinator {
    if (_coordinator != nil) {
        return _coordinator;
    }
    
    NSManagedObjectModel *model = [self model];
    
    if (!model) {
        return nil;
    }
    
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES};
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = nil;
    NSURL* sharedURL = [fileManager containerURLForSecurityApplicationGroupIdentifier:WLAppGroupIdentifier()];
    sharedURL = [sharedURL URLByAppendingPathComponent:@"CoreData.sqlite"];
    NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    documentsURL = [documentsURL URLByAppendingPathComponent:@"CoreData.sqlite"];
    if (sharedURL) {
#ifndef WRAPLIVE_EXTENSION_TERGET
        if (![fileManager fileExistsAtPath:[sharedURL absoluteString]] && [fileManager fileExistsAtPath:[documentsURL absoluteString]]) {
            [fileManager moveItemAtURL:documentsURL toURL:sharedURL error:NULL];
        }
#endif
        url = sharedURL;
    } else {
        url = documentsURL;
    }
    NSError *error = nil;
    
    _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    if (![_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&error]) {
        WLLog(@"WRAPLIVEKIT", @"Couldn't create persistent store so clearing the database.", error);
        [[NSFileManager defaultManager] removeItemAtURL:url error:NULL];
        [_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&error];
    }
    
    return _coordinator;
}

- (WLEntry*)cachedEntry:(NSString*)identifier {
    return [self.cachedEntries objectForKey:identifier];
}

- (void)cacheEntry:(WLEntry*)entry {
    if (entry.managedObjectContext == self.context) {
        [self.cachedEntries setObject:entry forKey:entry.identifier];
    }
}

- (void)uncacheEntry:(WLEntry *)entry {
    [self.cachedEntries removeObjectForKey:entry.identifier];
}

- (NSFetchRequest*)fetchRequestForClass:(Class)entryClass {
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setFetchLimit:1];
    request.entity = [entryClass entity];
    return request;
}

- (WLEntry*)entryOfClass:(Class)entryClass identifier:(NSString *)identifier {
    WLEntry* entry = [self cachedEntry:identifier];
    if (!entry) {
        if (!identifier.nonempty) return nil;
        NSFetchRequest* request = [self fetchRequestForClass:entryClass];
        request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@",identifier];
        entry = [[request execute] lastObject];
        if (!entry) {
            entry = [[entryClass alloc] initWithEntity:request.entity insertIntoManagedObjectContext:self.context];
            entry.identifier = identifier;
        }
    }
    return entry;
}

- (WLEntry*)entryOfClass:(Class)entryClass identifier:(NSString*)identifier uploadIdentifier:(NSString*)uploadIdentifier {
    if (!uploadIdentifier.nonempty) {
        return [self entryOfClass:entryClass identifier:identifier];
    }
    WLEntry* entry = [self cachedEntry:identifier];
    if (!entry) {
        if (!identifier.nonempty) return nil;
        NSFetchRequest* request = [self fetchRequestForClass:entryClass];
        request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@ OR uploadIdentifier == %@", identifier, uploadIdentifier];
        entry = [[request execute] lastObject];
        if (!entry) {
            entry = [[entryClass alloc] initWithEntity:request.entity insertIntoManagedObjectContext:self.context];
            entry.identifier = identifier;
        }
    }
    return entry;
}

- (BOOL)entryExists:(Class)entryClass identifier:(NSString *)identifier {
    if (!identifier.nonempty) return NO;
    
    if ([self.cachedEntries objectForKey:identifier] != nil) {
        return YES;
    }
    
    NSFetchRequest* request = [self fetchRequestForClass:entryClass];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@",identifier];
    return [self.context countForFetchRequest:request error:NULL] > 0;
}

- (NSMutableOrderedSet *)entriesOfClass:(Class)entryClass {
	return [self entriesOfClass:entryClass configure:nil];
}

- (NSMutableOrderedSet *)entriesOfClass:(Class)entryClass configure:(void (^)(NSFetchRequest *request))configure {
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    request.entity = [entryClass entity];
	if (configure) configure(request);
    return [NSMutableOrderedSet orderedSetWithArray:[request execute]];
}

- (void)deleteEntry:(WLEntry *)entry {
    if (entry) {
        [self.cachedEntries removeObjectForKey:entry.identifier];
        [self.context deleteObject:entry];
    }
}

- (void)save {
    __weak typeof(self)weakSelf = self;
    if ([weakSelf.context hasChanges] && weakSelf.coordinator.persistentStores.nonempty) {
        [weakSelf.context performBlock:^{
            NSError* error = nil;
            [weakSelf.context save:&error];
            if (weakSelf.assureSaveBlocks.nonempty) {
                NSSet *blocks = [weakSelf.assureSaveBlocks copy];
                for (WLBlock block in blocks) {
                    block();
                }
                [weakSelf.assureSaveBlocks minusSet:blocks];
            }
            if (error) {
                WLLog(@"CoreData", @"save error", error);
            }
        }];
    }
}

- (void)assureSave:(WLBlock)block {
    if (block) {
        if ([self.context hasChanges]) {
            [self.assureSaveBlocks addObject:block];
        } else {
            block();
        }
    }
}

- (void)clear {
    for (NSPersistentStore* store in self.coordinator.persistentStores) {
        NSError *error;
        NSURL *storeURL = store.URL;
        [self.coordinator removePersistentStore:store error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error];
    }
    self.coordinator = nil;
    self.context = nil;
    [self.cachedEntries removeAllObjects];
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)request {
    return [[WLEntryManager manager].context executeFetchRequest:request error:NULL];
}

- (NSManagedObjectContext *)backgroundContext {
    if (!_backgroundContext) {
        NSPersistentStoreCoordinator *coordinator = [self coordinator];
        if (coordinator != nil) {
            _backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            _backgroundContext.persistentStoreCoordinator = coordinator;
        }
    }
    return _backgroundContext;
}

- (void)performBlockInBackground:(WLEntryManagerBackgroundContextBlock)block success:(WLEntryManagerMainContextSuccessBlock)success failure:(WLEntryManagerMainContextFailureBlock)failure {
    NSManagedObjectContext *mainContext = self.context;
    NSManagedObjectContext *backgroundContext = self.backgroundContext;
    [self assureSave:^{
        [backgroundContext performBlock:^{
            NSError *error = nil;
            id result = nil;
            if (block) block(&result, &error, backgroundContext);
            [mainContext performBlock:^{
                if (error) {
                    if (failure) failure(error, mainContext);
                } else {
                    if (success) success(result, mainContext);
                }
            }];
        }];
    }];
}

- (void)executeFetchRequest:(NSFetchRequest *)request success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    [self performBlockInBackground:^(__autoreleasing id *objects, NSError *__autoreleasing *error, NSManagedObjectContext *backgroundContext) {
        *objects = [backgroundContext executeFetchRequest:request error:error];
    } success:^(NSArray *objects, NSManagedObjectContext *mainContext) {
        switch (request.resultType) {
            case NSManagedObjectResultType: {
                objects = [objects map:^id(NSManagedObject *object) {
                    return [mainContext existingObjectWithID:[object objectID] error:NULL];
                }];
            }   break;
            case NSManagedObjectIDResultType: {
                objects = [objects map:^id(NSManagedObjectID *objectID) {
                    return [mainContext existingObjectWithID:objectID error:NULL];
                }];
            }   break;
            case NSDictionaryResultType: {
                
            }   break;
            case NSCountResultType: {
                
            }   break;
            default:
                break;
        }
        if (success) success(objects);
    } failure:^(NSError *error, NSManagedObjectContext *mainContext) {
        if (failure) failure(error);
    }];
}

- (void)countForFetchRequest:(NSFetchRequest *)request success:(void (^)(NSUInteger))success failure:(WLFailureBlock)failure {
    [self performBlockInBackground:^(__autoreleasing id *objects, NSError *__autoreleasing *error, NSManagedObjectContext *backgroundContext) {
        *objects = [backgroundContext executeFetchRequest:request error:error];
    } success:^(id result, NSManagedObjectContext *mainContext) {
        if ([result isKindOfClass:[NSArray class]]) {
            if (success) success([result count]);
        } else if ([result isKindOfClass:[NSNumber class]]) {
            if (success) success([result unsignedIntegerValue]);
        } else {
            if (success) success(0);
        }
    } failure:^(NSError *error, NSManagedObjectContext *mainContext) {
        if (failure) failure(error);
    }];
}

@end

@implementation WLEntry (WLEntryManager)

+ (NSEntityDescription *)entity {
    static char *WLEntityDescriptionKey = "WLEntityDescriptionKey";
    NSEntityDescription *entity = objc_getAssociatedObject(self, WLEntityDescriptionKey);
    if (!entity) {
        entity = [NSEntityDescription entityForName:NSStringFromClass(self) inManagedObjectContext:[WLEntryManager manager].context];
        objc_setAssociatedObject(self, WLEntityDescriptionKey, entity, OBJC_ASSOCIATION_RETAIN);
    }
    return entity;
}

+ (instancetype)entry:(NSString *)identifier {
	return [[WLEntryManager manager] entryOfClass:self identifier:identifier];
}

+ (NSArray*)entries {
    return [[self fetchRequest] execute];
}

+ (NSArray *)entriesWithPredicate:(NSPredicate *)predicate {
    return [[self fetchRequestWithPredicate:predicate] execute];
}

+ (NSArray *)entriesWhere:(NSString *)predicateFormat, ... {
    BEGIN_PREDICATE_FORMAT
    id result = [self entriesWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
    END_PREDICATE_FORMAT
    return result;
}

+ (void)entries:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    [[self fetchRequest] execute:success failure:failure];
}

+ (void)entriesWithPredicate:(NSPredicate*)predicate success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    [[self fetchRequestWithPredicate:predicate] execute:success failure:failure];
}

+ (NSFetchRequest *)fetchRequest {
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    request.entity = [self entity];
    return request;
}

+ (NSFetchRequest *)fetchRequest:(NSString *)predicateFormat, ... {
    BEGIN_PREDICATE_FORMAT
    id result = [self fetchRequestWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
    END_PREDICATE_FORMAT
    return result;
}

+ (NSFetchRequest *)fetchRequestWithPredicate:(NSPredicate *)predicate {
    NSFetchRequest *request = [self fetchRequest];
    request.predicate = predicate;
    return request;
}

+ (BOOL)entryExists:(NSString*)identifier {
    return [[WLEntryManager manager] entryExists:self identifier:identifier];
}

- (void)save {
    [[WLEntryManager manager] save];
}

- (void)remove {
    __weak typeof(self)weakSelf = self;
    WLEntryManager *manager = [WLEntryManager manager];
    [manager assureSave:^{
        [weakSelf notifyOnDeleting:^(id object) {
            WLLog(@"WRAPLIVE", @"LOCAL DELETING", weakSelf);
            [manager deleteEntry:weakSelf];
        }];
    }];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    [[WLEntryManager manager] cacheEntry:self];
    if (!self.picture) {
        self.picture = [[WLPicture alloc] init];
    }
    self.createdAt = [NSDate now];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    [[WLEntryManager manager] cacheEntry:self];
}

- (void)prepareForDeletion {
    [super prepareForDeletion];
    [[WLEntryManager manager] uncacheEntry:self];
}

- (BOOL)valid {
    return self.managedObjectContext != nil && !self.deleted && (self.containingEntry ? self.containingEntry.valid : YES);
}

- (BOOL)invalid {
    return self.managedObjectContext == nil || self.deleted || (self.containingEntry ? self.containingEntry.invalid : NO);
}

@end

@implementation NSFetchRequest (WLEntryManager)

- (NSArray *)execute {
    return [[WLEntryManager manager] executeFetchRequest:self];
}

- (NSArray *)executeInContext:(NSManagedObjectContext *)context {
    return [context executeFetchRequest:self error:NULL];
}

- (void)execute:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    [[WLEntryManager manager] executeFetchRequest:self success:success failure:failure];
}

- (void)count:(void (^)(NSUInteger))success failure:(WLFailureBlock)failure {
    [[WLEntryManager manager] countForFetchRequest:self success:success failure:failure];
}

- (instancetype)limitedTo:(NSUInteger)limitedTo {
    self.fetchLimit = limitedTo;
    return self;
}

- (instancetype)sortedBy:(NSString *)sortedBy {
    return [self sortedBy:sortedBy ascending:NO];
}

- (instancetype)sortedBy:(NSString *)sortedBy ascending:(BOOL)ascending {
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithArray:self.sortDescriptors];
    [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:sortedBy ascending:ascending]];
    self.sortDescriptors = [sortDescriptors copy];
    return self;
}

- (instancetype)groupedBy:(NSArray *)propertiesToGroupBy fetch:(NSArray *)propertiesToFetch {
    self.resultType = NSDictionaryResultType;
    NSDictionary *namedProperies = self.entity.propertiesByName;
    
    NSMutableArray *_propertiesToGroupBy = [NSMutableArray arrayWithArray:self.propertiesToGroupBy];
    
    for (id propertyToGroupBy in propertiesToGroupBy) {
        if ([propertyToGroupBy isKindOfClass:[NSString class]]) {
            [_propertiesToGroupBy addObject:[namedProperies objectForKey:propertyToGroupBy]];
        } else {
            [_propertiesToGroupBy addObject:propertyToGroupBy];
        }
    }
    
    self.propertiesToGroupBy = [_propertiesToGroupBy copy];
    
    NSMutableArray *_propertiesToFetch = [NSMutableArray arrayWithArray:self.propertiesToFetch];
    
    for (id propertyToFetch in propertiesToFetch) {
        if ([propertyToFetch isKindOfClass:[NSString class]]) {
            [_propertiesToFetch addObject:[namedProperies objectForKey:propertyToFetch]];
        } else {
            [_propertiesToFetch addObject:propertyToFetch];
        }
    }
    
    self.propertiesToFetch = [_propertiesToFetch copy];
    return self;
}

@end
