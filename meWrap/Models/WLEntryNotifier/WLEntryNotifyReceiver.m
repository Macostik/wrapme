//
//  WLEntryNotifyReceiver.m
//  meWrap
//
//  Created by Ravenpod on 5/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntryNotifyReceiver.h"

@implementation WLEntryNotifyReceiver

+ (instancetype)receiverWithEntry:(WLEntry *)entry {
    WLEntryNotifyReceiver *receiver = [[self alloc] init];
    receiver.entry = entry;
    return receiver;
}

- (WLEntry *)container {
    if (self.containerBlock) {
        return self.containerBlock();
    }
    return _container;
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
    WLEntry *currentContainer = self.container;
    WLEntry *currentEntry = self.entry;
    if (currentContainer && currentContainer != entry.container) {
        return NO;
    }
    return currentEntry ? (currentEntry == entry) : YES;
}

- (void)notifier:(WLEntryNotifier *)notifier didAddEntry:(WLEntry *)entry {
    if (_didAddBlock) _didAddBlock(entry);
}

- (void)notifier:(WLEntryNotifier *)notifier didUpdateEntry:(WLEntry *)entry {
    if (_didUpdateBlock) _didUpdateBlock(entry);
}

- (void)notifier:(WLEntryNotifier *)notifier willDeleteEntry:(WLEntry *)entry {
    if (_willDeleteBlock) _willDeleteBlock(entry);
}

- (void)notifier:(WLEntryNotifier *)notifier willDeleteContainer:(WLEntry *)entry {
    if (_willDeleteContainingBlock) _willDeleteContainingBlock(entry);
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return [self shouldNotifyOnEntry:entry];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnContainer:(WLEntry *)entry {
    WLEntry *currentContainer = self.container;
    if (currentContainer && currentContainer != entry) {
        return NO;
    }
    return YES;
}

@end
