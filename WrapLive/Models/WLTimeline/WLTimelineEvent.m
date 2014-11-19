//
//  WLTimelineEvent.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTimelineEvent.h"
#import "WLEntryManager.h"
#import "NSString+Additions.h"
#import "NSDate+Additions.h"

@implementation WLTimelineEvent

+ (NSMutableOrderedSet *)events:(NSMutableOrderedSet *)entries {
    NSMutableOrderedSet* events = [NSMutableOrderedSet orderedSet];
    WLTimelineEvent* event = [[WLTimelineEvent alloc] init];
    for (WLContribution* entry in entries) {
        
        if (![event addEntry:entry]) {
            [events addObject:event];
            event = [[WLTimelineEvent alloc] init];
            [event addEntry:entry];
        }
        
        if (entry == [entries lastObject] && ![events containsObject:event]) {
            [events addObject:event];
        }
    }
    return events;
}

+ (NSMutableOrderedSet*)eventsByAddingEntry:(WLContribution*)entry toEvents:(NSMutableOrderedSet*)events {
    WLTimelineEvent *event = [events firstObject];
    if ([event addEntry:entry]) {
        [events sort:comparatorByDate];
        [event.entries sortByCreatedAt];
        return events;
    }
    event = [[WLTimelineEvent alloc] init];
    [event addEntry:entry];
    [events addObject:event];
    [events sort:comparatorByDate];
    return events;
}

+ (NSMutableOrderedSet*)eventsByDeletingEntry:(WLContribution*)entry fromEvents:(NSMutableOrderedSet*)events {
    NSMutableSet* emptyEvents = [NSMutableSet set];
    for (WLTimelineEvent* event in events) {
        [event deleteEntry:entry];
        if (!event.entries.nonempty) {
            [emptyEvents addObject:event];
        }
    }
    [events minusSet:emptyEvents];
    return events;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.entries = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

- (NSDate*)updatedAt {
    return self.date;
}

- (NSDate*)createdAt {
    return self.date;
}

- (BOOL)addEntry:(WLContribution *)entry {
    NSMutableOrderedSet *entries = self.entries;
    if (entries.nonempty) {
        if (self.entryClass != [entry class]) return NO;
        if (self.user != entry.contributor) return NO;
        if (![self.date isSameHour:entry.createdAt]) return NO;
        if (self.containingEntry != entry.containingEntry) return NO;
    }
    [entries addObject:entry];
    
    if (self.date == nil || [entry.createdAt later:self.date]) {
        self.date = entry.createdAt;
    }
    
    if (self.user == nil) {
        self.user = entry.contributor;
        self.entryClass = [entry class];
        self.containingEntry = [entry containingEntry];
    }
    
    return YES;
}

- (BOOL)deleteEntry:(WLContribution *)entry {
    NSMutableOrderedSet *entries = self.entries;
    if (self.entryClass == [entry class]) {
        if ([entries containsObject:entry]) {
            [entries removeObject:entry];
            return YES;
        }
    } else {
        if (self.containingEntry == entry) {
            [entries removeAllObjects];
        }
    }
    return NO;
}

- (NSString *)text {
    if (!_text) {
        if (self.entryClass == [WLComment class]) {
            _text = [NSString stringWithFormat:@"%@ made %@", WLString(_user.name), self.entries.count > 1 ? @"comments" : @"a comment"];
        } else {
            _text = [NSString stringWithFormat:@"%@ uploaded new photo%@", WLString(_user.name), self.entries.count > 1 ? @"s" : @""];
        }
    }
    return _text;
}

@end
