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

@implementation WLCandy

@dynamic commentCount;
@dynamic editedPicture;
@dynamic type;
@dynamic comments;
@dynamic wrap;

@synthesize latestComment = _latestComment;

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"comments" context:nil];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    [self addObserver:self forKeyPath:@"comments" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    [self addObserver:self forKeyPath:@"comments" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"comments"]) {
        self.latestComment = nil;
    }
}

- (WLComment *)latestComment {
    if (!_latestComment && self.comments.count > 0) {
        WLComment *comment = [[[NSMutableOrderedSet orderedSetWithSet:self.comments] sortByCreatedAt] firstObject];
        _latestComment = comment.valid ? comment : nil;
    }
    return _latestComment;
}

@end
