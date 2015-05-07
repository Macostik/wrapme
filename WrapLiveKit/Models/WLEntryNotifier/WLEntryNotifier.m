//
//  WLEntryNotifier.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntryNotifier.h"
#import "WLEntryManager.h"
#import "NSDate+Additions.h"
#import "WLOperationQueue.h"
#import "WLEntryNotifyReceiver.h"

@interface WLEntryNotifier ()

@property (strong, nonatomic) WLBroadcastSelectReceiver selectBlock;

@property (strong, nonatomic) NSMapTable* ownedReceivers;

@end

@implementation WLEntryNotifier

+ (instancetype)notifier {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

static NSMapTable* notifiers = nil;

+ (instancetype)notifier:(Class)entryClass {
	if (!notifiers) notifiers = [NSMapTable strongToStrongObjectsMapTable];
	WLEntryNotifier *notifier = [notifiers objectForKey:entryClass];
	if (!notifier) {
		notifier = [[self alloc] init];
		[notifiers setObject:notifier forKey:entryClass];
	}
	return notifier;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        __weak typeof(self)weakSelf = self;
        self.selectBlock = ^BOOL (NSObject <WLEntryNotifyReceiver> *receiver, WLEntry *entry) {
            if ([receiver respondsToSelector:@selector(notifier:shouldNotifyOnEntry:)]) {
                return [receiver notifier:weakSelf shouldNotifyOnEntry:entry];
            }
            return YES;
        };
    }
    return self;
}

- (void)notifyOnAddition:(WLEntry *)entry {
    [self broadcast:@selector(notifier:entryAdded:) object:entry select:self.selectBlock];
}

- (void)notifyOnUpdate:(WLEntry *)entry {
    [self broadcast:@selector(notifier:entryUpdated:) object:entry select:self.selectBlock];
}

- (void)notifyOnDeleting:(WLEntry *)entry {
    [self broadcast:@selector(notifier:entryDeleted:) object:entry select:self.selectBlock];
}

- (void)setReceiver:(id)receiver ownedBy:(id)owner {
    if (!self.ownedReceivers) self.ownedReceivers = [NSMapTable strongToWeakObjectsMapTable];
    [self.ownedReceivers setObject:owner forKey:receiver];
}

@end

@implementation WLEntry (WLEntryNotifier)

+ (WLEntryNotifier *)notifier {
	return [WLEntryNotifier notifier:self];
}

+ (WLEntryNotifyReceiver*)notifyReceiverOwnedBy:(id)owner {
    return [self notifyReceiverOwnedBy:owner setupBlock:nil];
}

+ (WLEntryNotifyReceiver*)notifyReceiverOwnedBy:(id)owner setupBlock:(WLEntryNotifyReceiverSetupBlock)setupBlock {
    WLEntryNotifyReceiver *receiver = [[WLEntryNotifyReceiver alloc] init];
    WLEntryNotifier *notifier = [self notifier];
    if (owner) {
        [notifier setReceiver:receiver ownedBy:owner];
    }
    [notifier addReceiver:receiver];
    if (setupBlock) setupBlock(receiver);
    return receiver;
}

- (instancetype)update:(NSDictionary *)dictionary {
	[self API_setup:dictionary];
    [self notifyOnUpdate];
	return self;
}

- (void)notifyOnAddition {
	[[WLEntryNotifier notifier:[self class]] notifyOnAddition:self];
	[self touchContainingEntry];
}

- (void)notifyOnUpdate {
	[[WLEntryNotifier notifier:[self class]] notifyOnUpdate:self];
	[self touchContainingEntry];
}

- (void)notifyOnDeleting {
	[[WLEntryNotifier notifier:[self class]] notifyOnDeleting:self];
	[self.containingEntry notifyOnUpdate];
}

- (void)touchContainingEntry {
	WLEntry* entry = self.containingEntry;
	if (entry) {
		if ([entry.updatedAt earlier:self.updatedAt]) entry.updatedAt = self.updatedAt;
		[entry notifyOnUpdate];
	}
}

@end
