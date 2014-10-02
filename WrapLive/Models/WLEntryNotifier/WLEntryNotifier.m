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

@interface WLEntryNotifier ()

@property (strong, nonatomic) WLBroadcastSelectReceiver selectBlock;

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

+ (instancetype)notifier:(Class)entryClass {
	static NSMapTable* notifiers = nil;
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

- (void)notifyOnAddition:(WLEntry *)entry {
	[self broadcast:entry.notifyOnAdditionSelector object:entry select:self.selectBlock];
}

- (void)notifyOnUpdate:(WLEntry *)entry {
	[self broadcast:entry.notifyOnUpdateSelector object:entry select:self.selectBlock];
}

- (void)notifyOnDeleting:(WLEntry *)entry {
	[self broadcast:entry.notifyOnDeletingSelector object:entry select:self.selectBlock];
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
    if (self.hasChanges) [self notifyOnUpdate];
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
