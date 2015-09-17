//
//  WLWrap.m
//  meWrap
//
//  Created by Ravenpod on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWrap.h"
#import "WLCandy.h"
#import "WLMessage.h"
#import "WLUser.h"
#import "WLCollections.h"

@interface WLWrap ()

@property (nonatomic) BOOL observing;

@end

@implementation WLWrap

@dynamic isCandyNotifiable;
@dynamic isChatNotifiable;
@dynamic isRestrictedInvite;
@dynamic name;
@dynamic candies;
@dynamic contributors;
@dynamic messages;
@dynamic isPublic;

@synthesize cover = _cover;
@synthesize recentCandies = _recentCandies;
@synthesize observing = _observing;

- (void)dealloc {
    if (self.observing) {
        [self removeObserver:self forKeyPath:@"candies" context:nil];
    }
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    [self addObserver:self forKeyPath:@"candies" options:NSKeyValueObservingOptionNew context:nil];
    self.observing = YES;
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    [self addObserver:self forKeyPath:@"candies" options:NSKeyValueObservingOptionNew context:nil];
    self.observing = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"candies"]) {
        self.cover = nil;
        self.recentCandies = nil;
    }
}

- (WLCandy *)cover {
    if (!_cover && self.candies.count > 0) {
        _cover = [[[self.candies array] sortByUpdatedAt] firstObject];
    }
    return _cover;
}

- (NSMutableOrderedSet *)recentCandies {
    if (!_recentCandies) {
        _recentCandies = (id)[[self.candies orderedSet] sortByUpdatedAt];
    }
    return _recentCandies;
}

@end
