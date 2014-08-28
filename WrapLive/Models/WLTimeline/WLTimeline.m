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

@interface WLTimeline () <WLWrapBroadcastReceiver>

@property (strong, nonatomic) NSFetchedResultsController* fetchedResults;

@property (strong, nonatomic) NSFetchRequest* fetchRequest;

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
        [[WLWrapBroadcaster broadcaster] addReceiver:self];
        self.fetchRequest = [[NSFetchRequest alloc] init];
        self.fetchRequest.entity = [WLCandy entity];
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
    NSDate* date = [NSDate serverTime];
    NSDate* startDate = [date beginOfDay];
    NSDate* endDate = [date endOfDay];
    
    compareTimecost(^{
        self.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"updatedAt >= %@ AND updatedAt <= %@ AND type == %d",startDate, endDate, WLCandyTypeImage];
        self.images = [NSMutableOrderedSet orderedSetWithArray:[[WLEntryManager manager].context executeFetchRequest:self.fetchRequest error:NULL]];
    }, ^{
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"updatedAt >= %@ AND updatedAt <= %@ AND type == %d",startDate, endDate, WLCandyTypeImage];
        self.images = [NSMutableOrderedSet orderedSetWithOrderedSet:[self.wrap.candies filteredOrderedSetUsingPredicate:predicate]];
        [self.images sortByUpdatedAtDescending];
    });
    
    [self resetEntries:[self events:startDate end:endDate]];
}

- (NSMutableOrderedSet*)events:(NSDate*)start end:(NSDate*)end {
    __weak typeof(self)weakSelf = self;
    return [NSMutableOrderedSet orderedSetWithBlock:^(NSMutableOrderedSet *set) {
        [set unionOrderedSet:[weakSelf eventsForAddedImages:start end:end]];
        [set unionOrderedSet:[weakSelf eventsForAddedComments:start end:end]];
        [set sortByCreatedAtDescending];
    }];
}

- (NSMutableOrderedSet*)eventsForAddedImages:(NSDate*)start end:(NSDate*)end {
    NSMutableOrderedSet* events = [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet* addedImages = [self.images selectObjects:^BOOL(WLCandy* image) {
        return [image.createdAt isSameDay:start];
    }];
    [addedImages sortByCreatedAtDescending];
    while (addedImages.nonempty) {
        WLUser* contributor = [[addedImages firstObject] contributor];
        NSMutableOrderedSet* userImages = [addedImages selectObjects:^BOOL(WLCandy* image) {
            return image.contributor == contributor;
        }];
        [events unionOrderedSet:[self eventsForAddedImages:userImages]];
        [addedImages minusOrderedSet:userImages];
    }
    return events;
}

- (NSMutableOrderedSet*)eventsForAddedImages:(NSMutableOrderedSet*)images {
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

- (NSMutableOrderedSet*)eventsForAddedComments:(NSDate*)start end:(NSDate*)end {
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
    }
    [self update];
    [self.delegate paginatedSetChanged:self];
    if(success) {
        success(entries);
    }
}

#pragma mark - WLWrapBroadcastReceiver

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster wrapChanged:(WLWrap *)wrap {
    [self update];
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyCreated:(WLCandy *)candy {
    
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster candyRemoved:(WLCandy *)candy {
    
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster commentCreated:(WLComment *)comment {
    
}

- (void)broadcaster:(WLWrapBroadcaster *)broadcaster commentRemoved:(WLComment *)comment {
    
}

- (WLWrap *)broadcasterPreferedWrap:(WLWrapBroadcaster *)broadcaster {
    return self.wrap;
}

- (WLCandyType)broadcasterPreferedCandyType:(WLWrapBroadcaster *)broadcaster {
    return WLCandyTypeImage;
}

@end
