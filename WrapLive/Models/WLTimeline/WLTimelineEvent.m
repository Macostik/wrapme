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

- (instancetype)init {
    self = [super init];
    if (self) {
        self.images = [NSMutableOrderedSet orderedSet];
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
    
    void (^add) (void) = ^ {
        [self.images addObject:entry];
        self.date = entry.createdAt;
        if (self.user == nil) {
            self.user = entry.contributor;
            self.type = [entry isKindOfClass:[WLComment class]] ? WLTimelineEventTypeComment : WLTimelineEventTypePhoto;
        }
    };
    
    if (!self.images.nonempty) {
        add();
        return YES;
    }
    
    if ([[self.images firstObject] isKindOfClass:[entry class]] && self.user == entry.contributor && [self.date isSameHour:entry.createdAt]) {
        add();
        return YES;
    }
    return NO;
}

- (NSString *)text {
    if (!_text) {
        if (self.type == WLTimelineEventTypeComment) {
            _text = [NSString stringWithFormat:@"%@ add comment", WLString(_user.name)];
        } else {
            _text = [NSString stringWithFormat:@"%@ add new photo", WLString(_user.name)];
        }
    }
    return _text;
}

@end
