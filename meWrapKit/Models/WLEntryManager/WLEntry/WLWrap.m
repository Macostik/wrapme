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

- (BOOL)isContributing {
    return [self.contributors containsObject:[WLUser currentUser]];
}

- (NSString *)contributorNamesWithYouAndAmount:(NSInteger)numberOfUsers {
    NSSet *contributors = self.contributors;
    if (contributors.count <= 1 || numberOfUsers == 0) return NSLocalizedString(@"you", nil);
    NSMutableString* names = [NSMutableString string];
    NSUInteger i = 0;
    for (WLUser *contributor in contributors) {
        if (i < numberOfUsers) {
            if (![contributor isCurrentUser]) {
                [names appendFormat:@"%@, ", contributor.name];
                ++i;
            }
        } else {
            [names appendFormat:@"%@ ...", NSLocalizedString(@"you", nil)];
            return names;
        }
    }
    [names appendString:NSLocalizedString(@"you", nil)];
    return names;
}

- (NSString *)contributorNames {
    return [self contributorNamesWithYouAndAmount:3];
}

- (WLAsset *)picture {
    return [self.cover picture];
}

- (BOOL)isFirstCreated {
    NSSet *wraps = [self.contributor.wraps where:@"contributor == %@", [WLUser currentUser]];
    return [wraps containsObject:self] && wraps.count == 1;
}

- (BOOL)requiresFollowing {
    return self.isPublic && !self.isContributing;
}

@end
