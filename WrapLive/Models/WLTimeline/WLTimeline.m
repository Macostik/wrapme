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

@interface WLTimeline () <WLWrapBroadcastReceiver>

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
    }
    return self;
}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    self.request = [WLCandiesRequest request:wrap];
    [self update];
}

- (void)update {
    NSDate* date = [NSDate date];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"updatedAt >= %@ AND updatedAt <= %@ AND type == %d",[date beginOfDay], [date endOfDay], WLCandyTypeImage];
    NSMutableOrderedSet* images = [NSMutableOrderedSet orderedSetWithOrderedSet:[self.wrap.candies filteredOrderedSetUsingPredicate:predicate]];
    self.images = [images mutableCopy];
    [images sortByUpdatedAtDescending];
    NSMutableOrderedSet* events = [[NSMutableOrderedSet alloc] init];
    while (images.nonempty) {
        WLUser* contributor = [[images firstObject] contributor];
        WLTimelineEvent* event = [[WLTimelineEvent alloc] init];
        predicate = [NSPredicate predicateWithFormat:@"contributor == %@", contributor];
        event.user = contributor;
        event.images = [[images filteredOrderedSetUsingPredicate:predicate] mutableCopy];
        event.date = [[event.images firstObject] updatedAt];
        event.text = [NSString stringWithFormat:@"%@ add new photo", contributor.name];
        [images minusOrderedSet:event.images];
        [events addObject:event];
    }
    [self resetEntries:events];
}

- (void)configureRequest:(WLPaginatedRequest *)request {
    if (!self.images.nonempty) {
        request.type = WLPaginatedRequestTypeFresh;
    } else {
        WLEntry* firstEntry = [self.images firstObject];
        WLEntry* lastEntry = [self.images firstObject];
        request.newer = [firstEntry updatedAt];
        request.older = [lastEntry updatedAt];
    }
}

- (void)handleResponse:(NSOrderedSet*)entries success:(WLOrderedSetBlock)success {
    NSDate* date = [NSDate date];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"updatedAt >= %@ AND updatedAt <= %@ AND type == %d",[date beginOfDay], [date endOfDay], WLCandyTypeImage];
    NSMutableOrderedSet* images = [NSMutableOrderedSet orderedSetWithOrderedSet:[entries filteredOrderedSetUsingPredicate:predicate]];
    if (!images.nonempty || [images isSubsetOfOrderedSet:self.images]) {
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
