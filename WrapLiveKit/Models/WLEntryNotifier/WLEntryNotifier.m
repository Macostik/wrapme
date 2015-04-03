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

@interface WLEntryNotifier ()

@property (strong, nonatomic) WLBroadcastSelectReceiver selectBlock;

@property (nonatomic) BOOL batchUpdating;

@property (strong, nonatomic) NSMutableArray* batchUpdatesNotifies;

@end

@implementation WLEntryNotifier

+ (void)initialize {
    WLOperationQueue *queue = [WLOperationQueue queueNamed:WLOperationFetchingDataQueue];
    [queue setStartQueueBlock:^{
        [self beginBatchUpdates];
    }];
    [queue setFinishQueueBlock:^{
        [self commitBatchUpdates];
    }];
}

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
			
			while (entry) {
				SEL preferredSelector = entry.notifyPreferredSelector;
				if ([receiver respondsToSelector:preferredSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
					return [receiver performSelector:preferredSelector withObject:weakSelf] == entry;
#pragma clang diagnostic pop
				}
				entry = entry.containingEntry;
			}
			
			return YES;
        };
    }
    return self;
}

+ (void)beginBatchUpdates {
    WLEntryNotifier *notifier = nil;
    NSEnumerator *enumerator = [notifiers objectEnumerator];
    while (notifier = [enumerator nextObject]) {
        [notifier beginBatchUpdates];
    }
}

+ (void)commitBatchUpdates {
    WLEntryNotifier *notifier = nil;
    NSEnumerator *enumerator = [notifiers objectEnumerator];
    while (notifier = [enumerator nextObject]) {
        [notifier commitBatchUpdates];
    }
}

- (void)beginBatchUpdates {
    self.batchUpdating = YES;
}

- (void)commitBatchUpdates {
    self.batchUpdating = NO;
    NSMutableArray *notifies = self.batchUpdatesNotifies;
    if (notifies.count > 0) {
        for (NSDictionary *notify in notifies) {
            WLEntry *entry = notify[@"entry"];
            NSString *selector = notify[@"selector"];
            [self broadcast:NSSelectorFromString(selector) object:entry select:self.selectBlock];
        }
        [notifies removeAllObjects];
    }
}

- (void)addBatchUpdatesNotify:(SEL)selector entry:(WLEntry*)entry {
    NSMutableArray *notifies = self.batchUpdatesNotifies;
    if (!notifies) {
        notifies = self.batchUpdatesNotifies = [NSMutableArray array];
    }
    NSString *selectorString = NSStringFromSelector(selector);
    for (NSDictionary *notify in notifies) {
        if (notify[@"entry"] == entry && [notify[@"selector"] isEqualToString:selectorString]) {
            [notifies removeObject:notify];
            break;
        }
    }
    [notifies addObject:@{@"entry":entry,@"selector":selectorString}];
}

- (void)notifyOnAddition:(WLEntry *)entry {
    if (self.batchUpdating) {
        [self addBatchUpdatesNotify:entry.notifyOnAdditionSelector entry:entry];
    } else {
        [self broadcast:entry.notifyOnAdditionSelector object:entry select:self.selectBlock];
    }
}

- (void)notifyOnUpdate:(WLEntry *)entry {
    if (self.batchUpdating) {
        [self addBatchUpdatesNotify:entry.notifyOnUpdateSelector entry:entry];
    } else {
        [self broadcast:entry.notifyOnUpdateSelector object:entry select:self.selectBlock];
    }
}

- (void)notifyOnDeleting:(WLEntry *)entry {
    if (self.batchUpdating) {
        [self addBatchUpdatesNotify:entry.notifyOnDeletingSelector entry:entry];
    } else {
        [self broadcast:entry.notifyOnDeletingSelector object:entry select:self.selectBlock];
    }
}

@end

@implementation WLEntry (WLEntryNotifier)

@dynamic notifyPreferredSelector;
@dynamic notifyOnAdditionSelector;
@dynamic notifyOnUpdateSelector;
@dynamic notifyOnDeletingSelector;

+ (WLEntryNotifier *)notifier {
	return [WLEntryNotifier notifier:self];
}

- (SEL)notifyPreferredSelector { return nil; }

- (SEL)notifyOnAdditionSelector { return nil; }

- (SEL)notifyOnUpdateSelector { return nil; }

- (SEL)notifyOnDeletingSelector { return nil; }

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

@implementation WLUser (WLEntryNotifier)

- (SEL)notifyPreferredSelector {
	return @selector(notifierPreferredUser:);
}

- (SEL)notifyOnAdditionSelector {
	return @selector(notifier:userAdded:);
}

- (SEL)notifyOnUpdateSelector {
	return @selector(notifier:userUpdated:);
}

- (SEL)notifyOnDeletingSelector {
	return @selector(notifier:userDeleted:);
}

@end

@implementation WLWrap (WLEntryNotifier)

- (SEL)notifyPreferredSelector {
	return @selector(notifierPreferredWrap:);
}

- (SEL)notifyOnAdditionSelector {
	return @selector(notifier:wrapAdded:);
}

- (SEL)notifyOnUpdateSelector {
	return @selector(notifier:wrapUpdated:);
}

- (SEL)notifyOnDeletingSelector {
	return @selector(notifier:wrapDeleted:);
}

@end

@implementation WLCandy (WLEntryNotifier)

- (SEL)notifyPreferredSelector {
	return @selector(notifierPreferredCandy:);
}

- (SEL)notifyOnAdditionSelector {
	return @selector(notifier:candyAdded:);
}

- (SEL)notifyOnUpdateSelector {
	return @selector(notifier:candyUpdated:);
}

- (SEL)notifyOnDeletingSelector {
	return @selector(notifier:candyDeleted:);
}

@end

@implementation WLMessage (WLEntryNotifier)

- (SEL)notifyPreferredSelector {
	return @selector(notifierPreferredMessage:);
}

- (SEL)notifyOnAdditionSelector {
	return @selector(notifier:messageAdded:);
}

- (SEL)notifyOnUpdateSelector {
	return @selector(notifier:messageUpdated:);
}

- (SEL)notifyOnDeletingSelector {
	return @selector(notifier:messageDeleted:);
}

@end

@implementation WLComment (WLEntryNotifier)

- (SEL)notifyPreferredSelector {
	return @selector(notifierPreferredComment:);
}

- (SEL)notifyOnAdditionSelector {
	return @selector(notifier:commentAdded:);
}

- (SEL)notifyOnUpdateSelector {
	return @selector(notifier:commentUpdated:);
}

- (SEL)notifyOnDeletingSelector {
	return @selector(notifier:commentDeleted:);
}

@end
