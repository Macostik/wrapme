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
    
    NSSet *contentClasses = [self.entryClass contentClasses];
    
    for (Class contentClass in contentClasses) {
        [[contentClass notifier] broadcast:@selector(notifier:willDeleteContainer:) object:entry select:self.selectContainerBlock];
    }
    
    [self broadcast:@selector(notifier:willDeleteEntry:) object:entry select:self.selectEntryBlock];
    if (block) block(entry);
    [self broadcast:@selector(notifier:didDeleteEntry:) object:entry select:self.selectEntryBlock];
    
    for (Class contentClass in contentClasses) {
        [[contentClass notifier] broadcast:@selector(notifier:didDeleteContainer:) object:entry select:self.selectContainerBlock];
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
	[self touchContainer];
    return self;
}

- (instancetype)notifyOnUpdate:(WLObjectBlock)block {
	[[WLEntryNotifier notifier:[self class]] notifyOnUpdate:self block:block];
	[self touchContainer];
    return self;
}

- (instancetype)notifyOnDeleting:(WLObjectBlock)block {
    WLEntry *container = self.container;
    [[WLEntryNotifier notifier:[self class]] notifyOnDeleting:self block:block];
	[container notifyOnUpdate:nil];
    return self;
}

- (void)touchContainer {
	WLEntry* entry = self.container;
	if (entry) {
		if ([entry.updatedAt earlier:self.updatedAt]) entry.updatedAt = self.updatedAt;
		[entry notifyOnUpdate:nil];
	}
}

@end
