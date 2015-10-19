//
//  WLCandy.m
//  meWrap
//
//  Created by Ravenpod on 7/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLCandy.h"
#import "WLComment.h"
#import "WLWrap.h"
#import "WLCollections.h"
#import "WLEntryManager.h"

@interface WLCandy ()

@property (nonatomic) BOOL observing;

@end

@implementation WLCandy

@dynamic commentCount;
@dynamic type;
@dynamic comments;
@dynamic wrap;

@synthesize latestComment = _latestComment;

@synthesize observing = _observing;

- (void)dealloc {
    if (self.observing) {
        [self removeObserver:self forKeyPath:@"comments" context:nil];
        [self removeObserver:self forKeyPath:@"updatedAt" context:nil];
    }
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    [self addObserver:self forKeyPath:@"comments" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"updatedAt" options:NSKeyValueObservingOptionNew context:nil];
    self.observing = YES;
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    [self addObserver:self forKeyPath:@"comments" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"updatedAt" options:NSKeyValueObservingOptionNew context:nil];
    self.observing = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"comments"]) {
        self.latestComment = nil;
    } else if ([keyPath isEqualToString:@"updatedAt"]) {
         self.wrap.recentCandies = nil;
    }
}

- (WLComment *)latestComment {
    if (!_latestComment && self.comments.count > 0) {
        WLComment *comment = [[[NSMutableOrderedSet orderedSetWithSet:self.comments] sortByCreatedAt] firstObject];
        _latestComment = comment.valid ? comment : nil;
    }
    return _latestComment;
}

- (BOOL)uploaded {
    return [super uploaded] && ![self.identifier isEqualToString:self.uploadIdentifier];
}

- (BOOL)canBeUploaded {
    return self.wrap.uploading == nil;
}

- (BOOL)deletable {
    return self.contributedByCurrentUser || self.wrap.contributedByCurrentUser;
}

- (NSMutableOrderedSet *)sortedComments {
    NSMutableOrderedSet* comments = [NSMutableOrderedSet orderedSetWithSet:self.comments];
    [comments sortByCreatedAt:NO];
    return comments;
}

- (BOOL)isVideo {
    return self.type == WLCandyTypeVideo;
}

- (NSString *)messageAppearanceByCandyType:(NSString *)firstString and:(NSString *)secondString {
    return self.isVideo ? NSLocalizedString(firstString, nil) : NSLocalizedString(secondString, nil);
}

@end
