//
//  WLEntryNotifier.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBroadcaster.h"
#import "WLEntryManager.h"

@class WLEntryNotifier;
@class WLEntryNotifyReceiver;

typedef void (^WLEntryNotifyReceiverSetupBlock) (WLEntryNotifyReceiver *receiver);

@protocol WLEntryNotifyReceiver <WLBroadcastReceiver>

@optional

- (BOOL)notifier:(WLEntryNotifier*)notifier shouldNotifyOnEntry:(WLEntry*)entry;

- (void)notifier:(WLEntryNotifier*)notifier entryAdded:(WLEntry*)entry;

- (void)notifier:(WLEntryNotifier*)notifier entryUpdated:(WLEntry*)entry;

- (void)notifier:(WLEntryNotifier*)notifier entryDeleted:(WLEntry*)entry;

@end

@interface WLEntryNotifier : WLBroadcaster

+ (instancetype)notifier;

+ (instancetype)notifier:(Class)entryClass;

- (void)notifyOnAddition:(WLEntry*)entry;

- (void)notifyOnUpdate:(WLEntry*)entry;

- (void)notifyOnDeleting:(WLEntry*)entry;

- (void)setReceiver:(id)receiver ownedBy:(id)owner;

@end

@interface WLEntry (WLEntryNotifier)

+ (WLEntryNotifier*)notifier;

+ (WLEntryNotifyReceiver*)notifyReceiverOwnedBy:(id)owner;

+ (WLEntryNotifyReceiver*)notifyReceiverOwnedBy:(id)owner setupBlock:(WLEntryNotifyReceiverSetupBlock)setupBlock;

- (void)notifyOnAddition;

- (void)notifyOnUpdate;

- (void)notifyOnDeleting;

- (instancetype)update:(NSDictionary*)dictionary;

@end
