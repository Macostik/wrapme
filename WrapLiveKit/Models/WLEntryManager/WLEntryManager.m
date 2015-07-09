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
    }
    return _context;
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
    [self.cachedEntries setObject:entry forKey:entry.identifier];
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
    run_after_asap(^{
        if ([weakSelf.context hasChanges] && weakSelf.coordinator.persistentStores.nonempty) {
            [weakSelf.context performBlock:^{
                NSError* error = nil;
                [weakSelf.context save:&error];
                if (error) {
                    WLLog(@"CoreData", @"save error", error);
                }
            }];
        }
    });
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

- (void)executeFetchRequest:(NSFetchRequest *)request success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    
    NSManagedObjectContext *mainContext = self.context;
    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    NSPersistentStoreCoordinator *coordinator = mainContext.persistentStoreCoordinator;
    
    [backgroundContext performBlock:^{
        backgroundContext.persistentStoreCoordinator = coordinator;
        
        NSError *error = nil;
        __block NSArray *objects = [backgroundContext executeFetchRequest:request error:&error];
        
        [mainContext performBlock:^{
            if (objects) {
                objects = [objects map:^id(NSManagedObject *object) {
                    return [mainContext objectWithID:[object objectID]];
                }];
                if (success) success(objects);
            } else {
                if (failure) failure(error);
            }
        }];
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

+ (NSMutableOrderedSet*)entries {
    return [self entries:nil];
}

+ (NSMutableOrderedSet *)entries:(void (^)(NSFetchRequest *))configure {
	return [[WLEntryManager manager] entriesOfClass:self configure:configure];
}

+ (NSMutableOrderedSet *)entriesWithPredicate:(NSPredicate *)predicate {
    return [self entries:^(NSFetchRequest *request) {
        request.predicate = predicate;
    }];
}

#define WL_PREDICATE_ARGUMENTS \
va_list args;\
va_start(args, predicateFormat);\
va_end(args);

+ (NSMutableOrderedSet *)entriesWhere:(NSString *)predicateFormat, ... {
    WL_PREDICATE_ARGUMENTS
    return [self entriesSortedBy:nil ascending:NO where:predicateFormat arguments:args];
}

+ (NSMutableOrderedSet *)entriesSortedBy:(NSString *)key where:(NSString *)predicateFormat, ... {
    WL_PREDICATE_ARGUMENTS
    return [self entriesSortedBy:key ascending:NO where:predicateFormat arguments:args];
}

+ (NSMutableOrderedSet *)entriesSortedBy:(NSString *)key ascending:(BOOL)ascending where:(NSString *)predicateFormat, ... {
    WL_PREDICATE_ARGUMENTS
    return [self entriesSortedBy:key ascending:ascending where:predicateFormat arguments:args];
}

+ (NSMutableOrderedSet *)entriesSortedBy:(NSString *)key ascending:(BOOL)ascending where:(NSString *)predicateFormat arguments:(va_list)args {
    if (![predicateFormat isKindOfClass:[NSString class]]) return nil;
    return [self entries:^(NSFetchRequest *request) {
        request.predicate = [NSPredicate predicateWithFormat:predicateFormat arguments:args];
        if (key) request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:key ascending:ascending]];
    }];
}

+ (void)entries:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    [self entries:nil success:success failure:failure];
}

+ (void)entriesWithPredicate:(NSPredicate*)predicate success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    [self entries:^(NSFetchRequest *request) {
        request.predicate = predicate;
    } success:success failure:failure];
}

+ (void)entries:(void (^)(NSFetchRequest* request))configure success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    request.entity = [self entity];
    if (configure) configure(request);
    [[WLEntryManager manager] executeFetchRequest:request success:success failure:failure];
}

+ (BOOL)entryExists:(NSString*)identifier {
    return [[WLEntryManager manager] entryExists:self identifier:identifier];
}

- (void)save {
    [[WLEntryManager manager] save];
}

- (void)remove {
    __weak typeof(self)weakSelf = self;
    [self notifyOnDeleting:^(id object) {
        WLLog(@"WRAPLIVE", @"LOCAL DELETING", weakSelf);
        [[WLEntryManager manager] deleteEntry:weakSelf];
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

- (void)execute:(WLArrayBlock)success failure:(WLFailureBlock)failure {
    [[WLEntryManager manager] executeFetchRequest:self success:success failure:failure];
}

@end
