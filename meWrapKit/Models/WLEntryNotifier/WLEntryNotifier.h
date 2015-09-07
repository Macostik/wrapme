//
//  WLEntryNotifier.h
//  meWrap
//
//  Created by Ravenpod on 11.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBroadcaster.h"
#import "WLEntryManager.h"

@class WLEntryNotifier;
@class WLEntryNotifyReceiver;

typedef void (^WLEntryNotifyReceiverSetupBlock) (WLEntryNotifyReceiver *receiver);

@protocol WLEntryNotifyReceiver <WLBroadcastReceiver>

@optional

- (BOOL)notifier:(WLEntryNotifier*)notifier shouldNotifyOnEntry:(WLEntry*)entry;

- (BOOL)notifier:(WLEntryNotifier*)notifier shouldNotifyOnContainer:(WLEntry*)entry;

- (void)notifier:(WLEntryNotifier*)notifier willAddEntry:(WLEntry*)entry;

- (void)notifier:(WLEntryNotifier*)notifier didAddEntry:(WLEntry*)entry;

- (void)notifier:(WLEntryNotifier*)notifier willUpdateEntry:(WLEntry*)entry;

- (void)notifier:(WLEntryNotifier*)notifier didUpdateEntry:(WLEntry*)entry;

- (void)notifier:(WLEntryNotifier*)notifier willDeleteEntry:(WLEntry*)entry;

- (void)notifier:(WLEntryNotifier*)notifier didDeleteEntry:(WLEntry*)entry;

- (void)notifier:(WLEntryNotifier*)notifier willDeleteContainer:(WLEntry*)entry;

- (void)notifier:(WLEntryNotifier*)notifier didDeleteContainer:(WLEntry*)entry;

@end

@interface WLEntryNotifier : WLBroadcaster

+ (instancetype)notifier;

+ (instancetype)notifier:(Class)entryClass;

- (void)notifyOnAddition:(WLEntry*)entry block:(WLObjectBlock)block;

- (void)notifyOnUpdate:(WLEntry*)entry block:(WLObjectBlock)block;

- (void)notifyOnDeleting:(WLEntry*)entry block:(WLObjectBlock)block;

@end

@interface WLEntry (WLEntryNotifier)

+ (WLEntryNotifier*)notifier;

+ (WLEntryNotifyReceiver*)notifyReceiverOwnedBy:(id)owner;

+ (WLEntryNotifyReceiver*)notifyReceiverOwnedBy:(id)owner setupBlock:(WLEntryNotifyReceiverSetupBlock)setupBlock;

- (instancetype)notifyOnAddition:(WLObjectBlock)block;

- (instancetype)notifyOnUpdate:(WLObjectBlock)block;

- (instancetype)notifyOnDeleting:(WLObjectBlock)block;

- (instancetype)update:(NSDictionary*)dictionary;

@end
