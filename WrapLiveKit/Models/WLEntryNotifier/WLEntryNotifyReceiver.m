//
//  WLEntryNotifyReceiver.m
//  wrapLive
//
//  Created by Sergey Maximenko on 5/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntryNotifyReceiver.h"

@implementation WLEntryNotifyReceiver

- (void)dealloc {
    NSLog(@"dealloc WLEntryNotifyReceiver");
}

+ (instancetype)receiverWithEntry:(WLEntry *)entry {
    WLEntryNotifyReceiver *receiver = [[self alloc] init];
    receiver.entry = entry;
    return receiver;
}

- (WLEntry *)containingEntry {
    if (self.containingEntryBlock) {
        return self.containingEntryBlock();
    }
    return _containingEntry;
}

- (WLEntry *)entry {
    if (self.entryBlock) {
        return self.entryBlock();
    }
    return _entry;
}

- (BOOL)shouldNotifyOnEntry:(WLEntry *)entry {
    if (self.shouldNotifyBlock) {
        return self.shouldNotifyBlock(entry);
    }
    WLEntry *currentContainingEntry = self.containingEntry;
    WLEntry *currentEntry = self.entry;
    if (currentContainingEntry && currentContainingEntry != entry.containingEntry) {
        return NO;
    }
    return currentEntry ? (currentEntry == entry) : YES;
}

- (void)notifier:(WLEntryNotifier *)notifier entryAdded:(WLEntry *)entry {
    if (_addedBlock) _addedBlock(entry);
}

- (void)notifier:(WLEntryNotifier *)notifier entryUpdated:(WLEntry *)entry {
    if (_updatedBlock) _updatedBlock(entry);
}

- (void)notifier:(WLEntryNotifier *)notifier entryDeleted:(WLEntry *)entry {
    if (_deletedBlock) _deletedBlock(entry);
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return [self shouldNotifyOnEntry:entry];
}

@end
