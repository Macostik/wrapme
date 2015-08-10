//
//  WLEntryNotifyReceiver.m
//  moji
//
//  Created by Ravenpod on 5/6/15.
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

- (void)notifier:(WLEntryNotifier *)notifier willAddEntry:(WLEntry *)entry {
    if (_willAddBlock) _willAddBlock(entry);
}

- (void)notifier:(WLEntryNotifier *)notifier didAddEntry:(WLEntry *)entry {
    if (_didAddBlock) _didAddBlock(entry);
}

- (void)notifier:(WLEntryNotifier *)notifier willUpdateEntry:(WLEntry *)entry {
    if (_willUpdateBlock) _willUpdateBlock(entry);
}

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLEntry *)entry {
    if (_didUpdateBlock) _didUpdateBlock(entry);
}

- (void)notifier:(WLEntryNotifier *)notifier willDeleteEntry:(WLEntry *)entry {
    if (_willDeleteBlock) _willDeleteBlock(entry);
}

- (void)notifier:(WLEntryNotifier *)notifier didDeleteEntry:(WLEntry *)entry {
    if (_didDeleteBlock) _didDeleteBlock(entry);
}

- (void)notifier:(WLEntryNotifier *)notifier willDeleteContainingEntry:(WLEntry *)entry {
    if (_willDeleteContainingBlock) _willDeleteContainingBlock(entry);
}

- (void)notifier:(WLEntryNotifier *)notifier didDeleteContainingEntry:(WLEntry *)entry {
    if (_didDeleteContainingBlock) _didDeleteContainingBlock(entry);
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return [self shouldNotifyOnEntry:entry];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnContainingEntry:(WLEntry *)entry {
    WLEntry *currentContainingEntry = self.containingEntry;
    if (currentContainingEntry && currentContainingEntry != entry) {
        return NO;
    }
    return YES;
}

@end
