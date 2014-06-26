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
#import "WLSupportFunctions.h"

@interface WLEntryManager ()

@property (strong, nonatomic) NSMutableDictionary* cachedEntries;

@end

@implementation WLEntryManager
{
    BOOL locked;
}

+ (instancetype)manager {
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (NSManagedObjectContext *)context {
    if (_context != nil) {
        return _context;
    }
    NSPersistentStoreCoordinator *coordinator = [self coordinator];
    if (coordinator != nil) {
        _context = [[NSManagedObjectContext alloc] init];
        [_context setPersistentStoreCoordinator:coordinator];
    }
    return _context;
}

- (NSManagedObjectModel *)model {
    if (_model != nil) {
        return _model;
    }
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"CoreData" withExtension:@"momd"];
    _model = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
    return _model;
}

- (NSPersistentStoreCoordinator *)coordinator {
    if (_coordinator != nil) {
        return _coordinator;
    }
    
    NSURL* url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:@"CoreData.sqlite"];
    NSError *error = nil;
    _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self model]];
    if (![_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
        
    }
    
    return _coordinator;
}
- (NSMutableDictionary *)cachedEntries {
    if (!_cachedEntries) {
        _cachedEntries = [NSMutableDictionary dictionary];
    }
    return _cachedEntries;
}

- (WLEntry*)cachedEntry:(NSString*)name identifier:(NSString*)identifier {
    NSMapTable* entries = [self.cachedEntries objectForKey:name];
    return [entries objectForKey:identifier];
}

- (void)cacheEntry:(WLEntry*)entry name:(NSString*)name identifier:(NSString*)identifier {
    NSMapTable* entries = [self.cachedEntries objectForKey:name];
    if (!entries) {
        entries = [NSMapTable strongToWeakObjectsMapTable];
        [self.cachedEntries setObject:entries forKey:name];
    }
    [entries setObject:entry forKey:identifier];
}

- (void)registerEntries:(NSOrderedSet *)entries forClass:(Class)entryClass {
    if (entries.nonempty) {
        NSMapTable* cachedEntries = [self.cachedEntries objectForKey:NSStringFromClass(entryClass)];
        for (WLEntry* entry in entries) {
            [cachedEntries setObject:entry forKey:entry.identifier];
        }
    }
}

- (void)registerEntry:(WLEntry *)entry {
    if (entry.identifier) {
        NSMapTable* entries = [self.cachedEntries objectForKey:[entry entity].name];
        [entries setObject:entry forKey:entry.identifier];
    }
}

- (WLEntry*)entryOfClass:(Class)entryClass identifier:(NSString *)identifier {
	if (!identifier.nonempty) {
		return nil;
	}
    NSEntityDescription* entity = [entryClass entity];
    WLEntry* entry = [self cachedEntry:entity.name identifier:identifier];
    if (!entry) {
        NSFetchRequest* request = [[NSFetchRequest alloc] init];
        request.entity = entity;
        request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@",identifier];
        entry = [[self.context executeFetchRequest:request error:NULL] lastObject];
        if (!entry) {
            entry = [[WLEntry alloc] initWithEntity:entity insertIntoManagedObjectContext:self.context];
            entry.identifier = identifier;
        }
        if (entry) {
            [self cacheEntry:entry name:entity.name identifier:identifier];
        }
    }
    return entry;
}

- (NSOrderedSet *)entriesOfClass:(Class)entryClass {
	return [self entriesOfClass:entryClass configure:nil];
}

- (NSOrderedSet *)entriesOfClass:(Class)entryClass configure:(void (^)(NSFetchRequest *request))configure {
    NSString* name = NSStringFromClass(entryClass);
    NSEntityDescription* entity = [NSEntityDescription entityForName:name inManagedObjectContext:self.context];
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    request.entity = entity;
	if (configure) {
		configure(request);
	}
    return [NSOrderedSet orderedSetWithArray:[self.context executeFetchRequest:request error:NULL]];
}

- (void)deleteEntry:(WLEntry *)entry {
    if (entry) {
        [self.context deleteObject:entry];
        [self save];
    }
}

- (void)save {
    if (!locked) {
        [self.context save:NULL];
    }
}

- (void)lock {
    locked = YES;
}

- (void)unlock {
    locked = NO;
    [self save];
}

@end

static char *WLEntityDescriptionKey = "WLEntityDescriptionKey";
static char *WLEntryPredicateKey = "WLEntryPredicateKey";
static char *WLEntrySubstitutionVariablesKey = "WLEntrySubstitutionVariablesKey";
static NSString *WLEntryIdentifierKey = @"identifier";

@implementation WLEntry (WLEntryManager)

+ (NSEntityDescription *)entity {
    NSEntityDescription* entity = objc_getAssociatedObject(self, WLEntityDescriptionKey);
    if (!entity) {
        entity = [NSEntityDescription entityForName:NSStringFromClass(self) inManagedObjectContext:[WLEntryManager manager].context];
        objc_setAssociatedObject(self, WLEntityDescriptionKey, entity, OBJC_ASSOCIATION_RETAIN);
    }
    return entity;
}

+ (NSPredicate *)predicate {
    NSPredicate* predicate = objc_getAssociatedObject(self, WLEntryPredicateKey);
    if (!predicate) {
        predicate = [NSPredicate predicateWithFormat:@"identifier = $identifier"];
        objc_setAssociatedObject(self, WLEntryPredicateKey, predicate, OBJC_ASSOCIATION_RETAIN);
    }
    return predicate;
}

+ (NSPredicate *)predicate:(NSString *)identifier {
    return [[self predicate] predicateWithSubstitutionVariables:[self substitutionVariables:identifier]];
}

+ (NSDictionary *)substitutionVariables:(NSString *)identifier {
    NSMutableDictionary* substitutionVariables = objc_getAssociatedObject(self, WLEntrySubstitutionVariablesKey);
    if (!substitutionVariables) {
        substitutionVariables = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, WLEntrySubstitutionVariablesKey, substitutionVariables, OBJC_ASSOCIATION_RETAIN);
    }
    [substitutionVariables setObject:identifier forKey:WLEntryIdentifierKey];
    return substitutionVariables;
}

+ (instancetype)entry:(NSString *)identifier {
	return [[WLEntryManager manager] entryOfClass:self identifier:identifier];
}

+ (NSOrderedSet*)entries {
    return [self entries:nil];
}

+ (NSOrderedSet *)entries:(void (^)(NSFetchRequest *))configure {
	return [[WLEntryManager manager] entriesOfClass:self configure:configure];
}

- (NSPredicate *)predicate {
    return [[[self class] predicate] predicateWithSubstitutionVariables:[self substitutionVariables]];
}

- (NSDictionary *)substitutionVariables {
    NSString* identifier = self.identifier;
    if (identifier.nonempty) {
        NSDictionary* substitutionVariables = objc_getAssociatedObject(self, WLEntrySubstitutionVariablesKey);
        if (!substitutionVariables) {
            substitutionVariables = @{@"identifier":identifier};
            objc_setAssociatedObject(self, WLEntrySubstitutionVariablesKey, substitutionVariables, OBJC_ASSOCIATION_RETAIN);
        }
        return substitutionVariables;
    }
    return nil;
}

- (void)save {
    return [[WLEntryManager manager] save];
}

- (void)remove {
    [[WLEntryManager manager] deleteEntry:self];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.updatedAt = [NSDate date];
    self.createdAt = [NSDate date];
    [[WLEntryManager manager] registerEntry:self];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    [[WLEntryManager manager] registerEntry:self];
}

@end
