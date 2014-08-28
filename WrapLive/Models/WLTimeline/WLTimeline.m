//
//  WLTimeline.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTimeline.h"
#import "WLWrap.h"
#import "WLWrapBroadcaster.h"
#import "WLTimelineEvent.h"
#import "WLCandiesRequest.h"
#import "WLSupportFunctions.h"
#import "WLServerTime.h"
#import "WLEntryFetching.h"

@interface WLTimeline ()

@property (strong, nonatomic) WLEntryFetching* fetching;

@end

@implementation WLTimeline

+ (instancetype)timelineWithWrap:(WLWrap *)wrap {
    WLTimeline* timeline = [[self alloc] init];
    timeline.wrap = wrap;
    return timeline;
}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    self.request = [WLCandiesRequest request:wrap];
    self.request.sameDay = YES;
    self.fetching = [WLEntryFetching fetching:@"timeline" configuration:^(NSFetchRequest *request) {
        request.entity = [WLCandy entity];
        NSDate* startDate = nil;
        NSDate* endDate = nil;
        [[NSDate serverTime] getBeginOfDay:&startDate endOfDay:&endDate];
        request.predicate = [NSPredicate predicateWithFormat:@"wrap == %@ AND updatedAt >= %@ AND updatedAt <= %@ AND type == %d", wrap,startDate, endDate, WLCandyTypeImage];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]];
    }];
    [self.fetching addTarget:self action:@selector(update)];
    [self.fetching perform];
    [self update];
}

- (void)update {
    self.images = self.fetching.content;
    [self resetEntries:[self events1:[NSDate serverTime]]];
}

- (NSMutableOrderedSet*)events:(NSDate*)date {
    __weak typeof(self)weakSelf = self;
    return [NSMutableOrderedSet orderedSetWithBlock:^(NSMutableOrderedSet *set) {
        [set unionOrderedSet:[weakSelf eventsForAddedImages:date]];
        [set unionOrderedSet:[weakSelf eventsForAddedComments:date]];
        [set sortByCreatedAtDescending];
    }];
}

- (NSMutableOrderedSet*)events1:(NSDate*)date {
    NSMutableOrderedSet* entries = [NSMutableOrderedSet orderedSet];
    for (WLCandy* image in self.images) {
        if ([image.createdAt isSameDay:date]) {
            [entries addObject:image];
        }
        
        for (WLComment* comment in image.comments) {
            if ([comment.createdAt isSameDay:date]) {
                [entries addObject:comment];
            }
        }
    }
    [entries sortByCreatedAtDescending];
    
    NSMutableOrderedSet* events = [NSMutableOrderedSet orderedSet];
    WLTimelineEvent* event = nil;
    for (WLContribution* entry in entries) {
        if (event == nil) {
            event = [[WLTimelineEvent alloc] init];
            event.user = entry.contributor;
            event.images = [NSMutableOrderedSet orderedSet];
            [event.images addObject:entry];
            event.date = entry.createdAt;
        } else if ([[event.images firstObject] isKindOfClass:[entry class]] && [[event.images firstObject] contributor] == entry.contributor) {
            [event.images addObject:entry];
            event.date = entry.createdAt;
        } else {
            if ([[event.images firstObject] isKindOfClass:[WLComment class]]) {
                event.images = [event.images map:^id(id item) {
                    return [item candy];
                }];
                event.text = [NSString stringWithFormat:@"%@ add comment", WLString(event.user.name)];
            } else {
                event.text = [NSString stringWithFormat:@"%@ add new photo", WLString(event.user.name)];
            }
            [events addObject:event];
            event = [[WLTimelineEvent alloc] init];
            event.user = entry.contributor;
            event.images = [NSMutableOrderedSet orderedSet];
            [event.images addObject:entry];
            event.date = entry.createdAt;
        }
        
        if (entry == [entries lastObject] && ![events containsObject:event]) {
            if ([[event.images firstObject] isKindOfClass:[WLComment class]]) {
                event.images = [event.images map:^id(id item) {
                    return [item candy];
                }];
                event.text = [NSString stringWithFormat:@"%@ add comment", WLString(event.user.name)];
            } else {
                event.text = [NSString stringWithFormat:@"%@ add new photo", WLString(event.user.name)];
            }
            [events addObject:event];
        }
    }
    
    return events;
}

- (NSMutableOrderedSet*)eventsForAddedImages:(NSDate*)date {
    NSMutableOrderedSet* events = [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet* addedImages = [self.images selectObjects:^BOOL(WLCandy* image) {
        return [image.createdAt isSameDay:date];
    }];
    [addedImages sortByCreatedAtDescending];
    while (addedImages.nonempty) {
        WLUser* contributor = [[addedImages firstObject] contributor];
        NSMutableOrderedSet* userImages = [addedImages selectObjects:^BOOL(WLCandy* image) {
            return image.contributor == contributor;
        }];
        [events unionOrderedSet:[self eventsForUserImages:userImages]];
        [addedImages minusOrderedSet:userImages];
    }
    return events;
}

- (NSMutableOrderedSet*)eventsForUserImages:(NSMutableOrderedSet*)images {
    NSMutableOrderedSet* events = [[NSMutableOrderedSet alloc] init];
    images = [images mutableCopy];
    while (images.nonempty) {
        WLCandy* firstImage = [images firstObject];
        WLTimelineEvent* event = [[WLTimelineEvent alloc] init];
        event.user = firstImage.contributor;
        event.images = [images selectObjects:^BOOL(WLCandy* image) {
            return [image.createdAt isSameHour:firstImage.createdAt];
        }];
        
        event.date = [[event.images firstObject] createdAt];
        event.text = [NSString stringWithFormat:@"%@ add new photo", WLString(firstImage.contributor.name)];
        [images minusOrderedSet:event.images];
        [events addObject:event];
    }
    return events;
}

- (NSMutableOrderedSet*)eventsForAddedComments:(NSDate*)date {
    NSMutableOrderedSet* events = [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet* comments = [NSMutableOrderedSet orderedSet];
    for (WLCandy* image in self.images) {
        for (WLComment* comment in image.comments) {
            if ([comment.createdAt isToday]) {
                [comments addObject:comment];
            }
        }
    }
    [comments sortByCreatedAtDescending];
    while (comments.nonempty) {
        WLUser* contributor = [[comments firstObject] contributor];
        WLTimelineEvent* event = [[WLTimelineEvent alloc] init];
        event.user = contributor;
        NSMutableOrderedSet* userComments = [comments selectObjects:^BOOL(WLComment* comment) {
            return comment.contributor == contributor;
        }];
        event.images = [userComments map:^id(WLComment* comment) {
            return comment.candy;
        }];
        event.date = [[userComments firstObject] createdAt];
        event.text = [NSString stringWithFormat:@"%@ add comment", WLString(contributor.name)];
        [comments minusOrderedSet:userComments];
        [events addObject:event];
    }
    return events;
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

@end
