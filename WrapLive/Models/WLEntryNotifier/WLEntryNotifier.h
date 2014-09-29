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

@protocol WLEntryNotifyReceiver

@optional

- (WLUser*)notifierPreferredUser:(WLEntryNotifier*)notifier;

- (WLWrap*)notifierPreferredWrap:(WLEntryNotifier*)notifier;

- (WLCandy*)notifierPreferredCandy:(WLEntryNotifier*)notifier;

- (WLMessage*)notifierPreferredMessage:(WLEntryNotifier*)notifier;

- (WLComment*)notifierPreferredComment:(WLEntryNotifier*)notifier;

- (void)notifier:(WLEntryNotifier*)notifier userAdded:(WLUser*)user;

- (void)notifier:(WLEntryNotifier*)notifier userUpdated:(WLUser*)user;

- (void)notifier:(WLEntryNotifier*)notifier userDeleted:(WLUser*)user;

- (void)notifier:(WLEntryNotifier*)notifier wrapAdded:(WLWrap*)wrap;

- (void)notifier:(WLEntryNotifier*)notifier wrapUpdated:(WLWrap*)wrap;

- (void)notifier:(WLEntryNotifier*)notifier wrapDeleted:(WLWrap*)wrap;

- (void)notifier:(WLEntryNotifier*)notifier candyAdded:(WLCandy*)candy;

- (void)notifier:(WLEntryNotifier*)notifier candyUpdated:(WLCandy*)candy;

- (void)notifier:(WLEntryNotifier*)notifier candyDeleted:(WLCandy*)candy;

- (void)notifier:(WLEntryNotifier*)notifier messageAdded:(WLMessage*)message;

- (void)notifier:(WLEntryNotifier*)notifier messageUpdated:(WLMessage*)message;

- (void)notifier:(WLEntryNotifier*)notifier messageDeleted:(WLMessage*)message;

- (void)notifier:(WLEntryNotifier*)notifier commentAdded:(WLComment*)comment;

- (void)notifier:(WLEntryNotifier*)notifier commentUpdated:(WLComment*)comment;

- (void)notifier:(WLEntryNotifier*)notifier commentDeleted:(WLComment*)comment;

@end

@interface WLEntryNotifier : WLBroadcaster

+ (instancetype)notifier;

+ (instancetype)notifier:(Class)entryClass;

- (void)notifyOnAddition:(WLEntry*)entry;

- (void)notifyOnUpdate:(WLEntry*)entry;

- (void)notifyOnDeleting:(WLEntry*)entry;

@end

@interface WLEntry (WLEntryNotifier)

@property (readonly, nonatomic) WLEntry* containingEntry;

@property (readonly, nonatomic) SEL notifyPreferredSelector;

@property (readonly, nonatomic) SEL notifyOnAdditionSelector;

@property (readonly, nonatomic) SEL notifyOnUpdateSelector;

@property (readonly, nonatomic) SEL notifyOnDeletingSelector;

+ (WLEntryNotifier*)notifier;

- (void)notifyOnAddition;

- (void)notifyOnUpdate;

- (void)notifyOnDeleting;

- (instancetype)update:(NSDictionary*)dictionary;

@end

@interface WLUser (WLEntryNotifier) @end

@interface WLWrap (WLEntryNotifier) @end

@interface WLCandy (WLEntryNotifier) @end

@interface WLMessage (WLEntryNotifier) @end

@interface WLComment (WLEntryNotifier) @end
