//
//  WLEntryDescriptor.m
//  meWrap
//
//  Created by Sergey Maximenko on 9/25/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import "WLEntryDescriptor.h"

@implementation WLEntryDescriptor

- (BOOL)entryExists {
    return [[EntryContext sharedContext] hasEntry:self.entityName uid:self.identifier];
}

@end

@implementation EntryContext (WLEntryDescriptor)

- (void)fetchEntries:(NSMutableDictionary *)descriptors {
    
    NSMutableArray *uids = [NSMutableArray arrayWithCapacity:descriptors.count];
    NSMutableArray *locuids = [NSMutableArray arrayWithCapacity:descriptors.count];
    
    NSDictionary *_descriptors = descriptors.copy;
    for (NSString *identifier in _descriptors) {
        WLEntryDescriptor *descriptor = _descriptors[identifier];
        if ([self cachedEntry:descriptor.identifier]) {
            [descriptors removeObjectForKey:descriptor.identifier];
        } else if ([self cachedEntry:descriptor.uploadIdentifier]) {
            [descriptors removeObjectForKey:descriptor.uploadIdentifier];
        } else {
            if (descriptor.identifier) {
                [uids addObject:descriptor.identifier];
            }
            if (descriptor.uploadIdentifier) {
                [locuids addObject:descriptor.uploadIdentifier];
            }
        }
    }
    
    if (descriptors.count == 0) {
        return;
    }
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"WLEntry"];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier IN %@ OR uploadIdentifier IN %@", uids, locuids];
    NSArray *array = [request execute];
    for (Entry *entry in array) {
        
        WLEntryDescriptor *descriptor = nil;
        for (NSString *identifier in descriptors) {
            WLEntryDescriptor *_descriptor = descriptors[identifier];
            if ([_descriptor.identifier isEqualToString:entry.identifier] || [_descriptor.uploadIdentifier isEqualToString:entry.uploadIdentifier]) {
                descriptor = _descriptor;
                break;
            }
        }
        if (descriptor) {
            [descriptors removeObjectForKey:descriptor.identifier];
            [self.cachedEntries setObject:entry forKey:descriptor.identifier];
        } else {
            [self.cachedEntries setObject:entry forKey:entry.identifier];
        }
    }
    
    [descriptors enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, WLEntryDescriptor *descriptor, BOOL *stop) {
        Entry *entry = [NSEntityDescription insertNewObjectForEntityForName:descriptor.entityName inManagedObjectContext:self];
        entry.identifier = descriptor.identifier;
        entry.uploadIdentifier = descriptor.uploadIdentifier;
        [self.cachedEntries setObject:entry forKey:entry.identifier];
    }];
}

@end
