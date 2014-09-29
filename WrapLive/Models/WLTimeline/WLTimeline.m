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
#import "WLSupportFunctions.h"
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
    self.fetching = [WLEntryFetching fetching:nil configuration:^(NSFetchRequest *request) {
        request.entity = [WLCandy entity];
        NSDate* startDate = [[NSDate now] beginOfDay];
        request.predicate = [NSPredicate predicateWithFormat:@"wrap == %@ AND updatedAt >= %@", wrap, startDate];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]];
    }];
    [self.fetching addTarget:self action:@selector(update)];
    [self.fetching perform];
    [self update];
}

- (void)update {
    self.images = self.fetching.content;
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
    [entries sortByCreatedAtDescending];
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

@end
