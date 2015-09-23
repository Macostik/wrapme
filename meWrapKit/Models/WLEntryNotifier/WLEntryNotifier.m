//
//  WLEntryNotifier.m
//  meWrap
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

@property (strong, nonatomic) WLBroadcastSelectReceiver selectContainerBlock;

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
        self.selectContainerBlock = ^BOOL(NSObject <WLEntryNotifyReceiver> *receiver, WLEntry *entry) {
            if ([receiver respondsToSelector:@selector(notifier:shouldNotifyOnContainer:)]) {
                return [receiver notifier:weakSelf shouldNotifyOnContainer:entry];
            }
            return YES;
        };
    }
    return self;
}

- (void)notifyOnAddition:(WLEntry *)entry {
    [self broadcast:@selector(notifier:didAddEntry:) object:entry select:self.selectEntryBlock];
}

- (void)notifyOnUpdate:(WLEntry *)entry {
    [self broadcast:@selector(notifier:didUpdateEntry:) object:entry select:self.selectEntryBlock];
}

- (void)notifyOnDeleting:(WLEntry *)entry {
    
    for (Class contentClass in [self.entryClass contentClasses]) {
        [[contentClass notifier] broadcast:@selector(notifier:willDeleteContainer:) object:entry select:self.selectContainerBlock];
    }
    
    [self broadcast:@selector(notifier:willDeleteEntry:) object:entry select:self.selectEntryBlock];
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
	[self API_setup:dictionary];
    if (self.updated) {
        [self notifyOnUpdate];
    }
	return self;
}

- (instancetype)notifyOnAddition {
	[[WLEntryNotifier notifier:[self class]] notifyOnAddition:self];
	[self touchContainer];
    return self;
}

- (instancetype)notifyOnUpdate {
	[[WLEntryNotifier notifier:[self class]] notifyOnUpdate:self];
	[self touchContainer];
    return self;
}

- (instancetype)notifyOnDeleting {
    [[WLEntryNotifier notifier:[self class]] notifyOnDeleting:self];
    return self;
}

- (void)touchContainer {
	WLEntry* entry = self.container;
	if (entry) {
		if ([entry.updatedAt earlier:self.updatedAt]) entry.updatedAt = self.updatedAt;
		[entry notifyOnUpdate];
	}
}

@end
