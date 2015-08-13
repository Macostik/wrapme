//
//  WLEntryNotifier.m
//  moji
//
//  Created by Ravenpod on 11.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntryNotifier.h"
#import "WLEntryManager.h"
#import "NSDate+Additions.h"
#import "WLOperationQueue.h"
#import "WLEntryNotifyReceiver.h"
#import "NSObject+AssociatedObjects.h"

@interface WLEntryNotifier ()

@property (strong, nonatomic) Class entryClass;

@property (strong, nonatomic) WLBroadcastSelectReceiver selectEntryBlock;

@property (strong, nonatomic) WLBroadcastSelectReceiver selectContainingEntryBlock;

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
        notifier.entryClass = entryClass;
		[notifiers setObject:notifier forKey:entryClass];
	}
	return notifier;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        __weak typeof(self)weakSelf = self;
        self.selectEntryBlock = ^BOOL (NSObject <WLEntryNotifyReceiver> *receiver, WLEntry *entry) {
            if ([receiver respondsToSelector:@selector(notifier:shouldNotifyOnEntry:)]) {
                return [receiver notifier:weakSelf shouldNotifyOnEntry:entry];
            }
            return YES;
        };
        self.selectContainingEntryBlock = ^BOOL(NSObject <WLEntryNotifyReceiver> *receiver, WLEntry *entry) {
            if ([receiver respondsToSelector:@selector(notifier:shouldNotifyOnContainingEntry:)]) {
                return [receiver notifier:weakSelf shouldNotifyOnContainingEntry:entry];
            }
            return YES;
        };
    }
    return self;
}

- (void)notifyOnAddition:(WLEntry *)entry block:(WLObjectBlock)block {
    [self broadcast:@selector(notifier:willAddEntry:) object:entry select:self.selectEntryBlock];
    if (block) block(entry);
    [self broadcast:@selector(notifier:didAddEntry:) object:entry select:self.selectEntryBlock];
}

- (void)notifyOnUpdate:(WLEntry *)entry block:(WLObjectBlock)block {
    [self broadcast:@selector(notifier:willUpdateEntry:) object:entry select:self.selectEntryBlock];
    if (block) block(entry);
    [self broadcast:@selector(notifier:didUpdateEntry:) object:entry select:self.selectEntryBlock];
}

- (void)notifyOnDeleting:(WLEntry *)entry block:(WLObjectBlock)block {
    
    NSSet *containedEntryClasses = [self.entryClass containedEntryClasses];
    
    for (Class containedEntryClass in containedEntryClasses) {
        [[containedEntryClass notifier] broadcast:@selector(notifier:willDeleteContainingEntry:) object:entry select:self.selectContainingEntryBlock];
    }
    
    [self broadcast:@selector(notifier:willDeleteEntry:) object:entry select:self.selectEntryBlock];
    if (block) block(entry);
    [self broadcast:@selector(notifier:didDeleteEntry:) object:entry select:self.selectEntryBlock];
    
    for (Class containedEntryClass in containedEntryClasses) {
        [[containedEntryClass notifier] broadcast:@selector(notifier:didDeleteContainingEntry:) object:entry select:self.selectContainingEntryBlock];
    }
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
        [owner setAssociatedObject:receiver forKey:[[NSString stringWithFormat:@"%@_notify_receiver", NSStringFromClass(self)] UTF8String]];
    }
    [notifier addReceiver:receiver];
    if (setupBlock) setupBlock(receiver);
    return receiver;
}

- (instancetype)update:(NSDictionary *)dictionary {
	__weak typeof(self)weakSelf = self;
    [self notifyOnUpdate:^(id object) {
        [weakSelf API_setup:dictionary];
    }];
	return self;
}

- (instancetype)notifyOnAddition:(WLObjectBlock)block {
	[[WLEntryNotifier notifier:[self class]] notifyOnAddition:self block:block];
	[self touchContainingEntry];
    return self;
}

- (instancetype)notifyOnUpdate:(WLObjectBlock)block {
	[[WLEntryNotifier notifier:[self class]] notifyOnUpdate:self block:block];
	[self touchContainingEntry];
    return self;
}

- (instancetype)notifyOnDeleting:(WLObjectBlock)block {
    WLEntry *containingEntry = self.containingEntry;
    [[WLEntryNotifier notifier:[self class]] notifyOnDeleting:self block:block];
	[containingEntry notifyOnUpdate:nil];
    return self;
}

- (void)touchContainingEntry {
	WLEntry* entry = self.containingEntry;
	if (entry) {
		if ([entry.updatedAt earlier:self.updatedAt]) entry.updatedAt = self.updatedAt;
		[entry notifyOnUpdate:nil];
	}
}

@end
