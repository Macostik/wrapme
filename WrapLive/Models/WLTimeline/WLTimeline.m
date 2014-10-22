//
//  WLTimeline.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTimeline.h"
#import "WLWrap.h"
#import "WLEntryNotifier.h"
#import "WLTimelineEvent.h"
#import "WLCandiesRequest.h"
#import "WLEntryFetching.h"

@interface WLTimeline () <WLEntryNotifyReceiver>

@end

@implementation WLTimeline

+ (instancetype)timelineWithWrap:(WLWrap *)wrap {
    WLTimeline* timeline = [[self alloc] init];
    timeline.wrap = wrap;
    return timeline;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[WLCandy notifier] addReceiver:self];
        [[WLComment notifier] addReceiver:self];
    }
    return self;
}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    self.request = [WLCandiesRequest request:wrap];
    self.request.sameDay = YES;
    [self update];
}

- (void)update {
    NSDate* startDate = [[NSDate now] beginOfDay];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"updatedAt >= %@", startDate];
    self.images = [NSMutableOrderedSet orderedSetWithOrderedSet:[self.wrap.candies filteredOrderedSetUsingPredicate:predicate]];
    [self.images sortByCreatedAt];
    [self resetEntries:[self events:[NSDate now]]];
}

- (NSMutableOrderedSet*)events:(NSDate*)date {
    NSDateComponents* c = [date dayComponents];
    NSMutableOrderedSet* entries = [NSMutableOrderedSet orderedSet];
    for (WLCandy* image in self.images) {
        if ([image.createdAt isSameDayComponents:c]) [entries addObject:image];
        for (WLComment* comment in image.comments) {
            if ([comment.createdAt isSameDayComponents:c]) [entries addObject:comment];
        }
    }
    [entries sortByCreatedAt];
    return [WLTimelineEvent events:entries];
}

- (void)configureRequest:(WLPaginatedRequest *)request {
    if (!self.images.nonempty) {
        request.type = WLPaginatedRequestTypeFresh;
    } else {
        WLEntry* firstEntry = [self.images firstObject];
        WLEntry* lastEntry = [self.images lastObject];
        request.newer = [firstEntry updatedAt];
        request.older = [lastEntry updatedAt];
    }
}

- (void)handleResponse:(NSOrderedSet*)entries success:(WLOrderedSetBlock)success {
    
    if (!entries.nonempty) {
        self.completed = YES;
    } else {
        NSUInteger count = [self.images count];
        [self update];
        if (count == [self.images count]) {
            self.completed = YES;
        }
    }
    
    [self.delegate paginatedSetChanged:self];
    if(success) {
        success(entries);
    }
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier candyAdded:(WLCandy *)candy {
    if (![candy.createdAt isToday]) return;
    [self.images addObject:candy];
    [self.images sortByCreatedAt];
    [WLTimelineEvent eventsByAddingEntry:candy toEvents:self.entries];
    [self.delegate paginatedSetChanged:self];
}

- (void)notifier:(WLEntryNotifier *)notifier candyDeleted:(WLCandy *)candy {
    [self.images removeObject:candy];
    [WLTimelineEvent eventsByDeletingEntry:candy fromEvents:self.entries];
    [self.delegate paginatedSetChanged:self];
}

- (void)notifier:(WLEntryNotifier *)notifier commentAdded:(WLComment *)comment {
    if (![comment.createdAt isToday]) return;
    [WLTimelineEvent eventsByAddingEntry:comment toEvents:self.entries];
    [self.delegate paginatedSetChanged:self];
}

- (void)notifier:(WLEntryNotifier *)notifier commentDeleted:(WLComment *)comment {
    [WLTimelineEvent eventsByDeletingEntry:comment fromEvents:self.entries];
    [self.delegate paginatedSetChanged:self];
}

- (WLWrap *)notifierPreferredWrap:(WLEntryNotifier *)notifier {
    return self.wrap;
}

@end
