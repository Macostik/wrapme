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
    WLTimelineEvent* event = nil;
    for (WLTimelineEvent* _event in events) {
        if ([_event.entries containsObject:entry]) {
            event = _event;
            break;
        }
    }
    if (event) {
        [event.entries removeObject:entry];
        if (!event.entries.nonempty) {
            [events removeObject:event];
        }
    }
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
    
    if (self.entries.nonempty) {
        if (self.entryClass != [entry class]) return NO;
        if (self.user != entry.contributor) return NO;
        if (![self.date isSameHour:entry.createdAt]) return NO;
    }
    [self.entries addObject:entry];
    
    if (self.date == nil || [entry.createdAt later:self.date]) {
        self.date = entry.createdAt;
    }
    
    if (self.user == nil) {
        self.user = entry.contributor;
        self.entryClass = [entry class];
    }
    
    return YES;
}

- (NSString *)text {
    if (!_text) {
        if (self.entryClass == [WLComment class]) {
            _text = [NSString stringWithFormat:@"%@ added comment%@", WLString(_user.name), self.entries.count > 1 ? @"s" : @""];
        } else {
            _text = [NSString stringWithFormat:@"%@ added new photo%@", WLString(_user.name), self.entries.count > 1 ? @"s" : @""];
        }
    }
    return _text;
}

@end
