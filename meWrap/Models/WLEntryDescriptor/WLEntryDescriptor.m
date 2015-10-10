//
//  WLEntryDescriptor.m
//  meWrap
//
//  Created by Sergey Maximenko on 9/25/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import "WLEntryDescriptor.h"

@implementation WLEntryDescriptor @end

@implementation WLEntryManager (WLEntryDescriptor)

- (void)fetchEntries:(NSMutableDictionary *)descriptors {
    
    NSMutableArray *keysToRemove = [NSMutableArray array];
    for (NSString *identifier in descriptors) {
        if ([self cachedEntry:identifier]) {
            [keysToRemove addObject:identifier];
        }
    }
    [descriptors removeObjectsForKeys:keysToRemove];
    
    if (descriptors.count == 0) {
        return;
    }
    
    NSMutableArray *uids = [NSMutableArray arrayWithCapacity:descriptors.count];
    NSMutableArray *locuids = [NSMutableArray arrayWithCapacity:descriptors.count];
    
    [descriptors enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, WLEntryDescriptor *descriptor, BOOL *stop) {
        if (descriptor.identifier) {
            [uids addObject:descriptor.identifier];
        }
        if (descriptor.uploadIdentifier) {
            [locuids addObject:descriptor.uploadIdentifier];
        }
    }];
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"WLEntry"];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier IN %@ OR uploadIdentifier IN %@", uids, locuids];
    NSArray *array = [request execute];
    for (WLEntry *entry in array) {
        [self.cachedEntries setObject:entry forKey:entry.identifier];
        if (entry.identifier) {
            [descriptors removeObjectForKey:entry.identifier];
        }
        if (entry.uploadIdentifier) {
            [descriptors removeObjectForKey:entry.uploadIdentifier];
        }
    }
    
    [descriptors enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, WLEntryDescriptor *descriptor, BOOL *stop) {
        WLEntry *entry = [[descriptor.entryClass alloc] initWithEntity:[descriptor.entryClass entity] insertIntoManagedObjectContext:self.context];
        entry.identifier = descriptor.identifier;
        entry.uploadIdentifier = descriptor.uploadIdentifier;
        [self.cachedEntries setObject:entry forKey:entry.identifier];
    }];
}

@end
