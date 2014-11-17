//
//  WLCandy.m
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandy+Extended.h"
#import "WLEntryManager.h"
#import "WLEntryNotifier.h"
#import "NSString+Additions.h"

@implementation WLCandy (Extended)

+ (NSNumber *)uploadingOrder {
    return @2;
}

+ (instancetype)candyWithType:(NSInteger)type wrap:(WLWrap*)wrap {
    WLCandy* candy = [self contribution];
    candy.type = @(type);
    [wrap addCandy:candy];
    return candy;
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return [dictionary stringForKey:WLCandyUIDKey];
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    [super API_setup:dictionary relatedEntry:relatedEntry];
    NSNumber* type = [dictionary numberForKey:WLCandyTypeKey];
    if (!NSNumberEqual(self.type, type)) self.type = type;
    NSArray *commentsArray = [dictionary arrayForKey:WLCommentsKey];
    NSMutableOrderedSet* comments = self.comments;
    if (!comments) {
        comments = [NSMutableOrderedSet orderedSetWithCapacity:[commentsArray count]];
        self.comments = comments;
    }
    [WLComment API_entries:commentsArray relatedEntry:self container:comments];
    if (comments.nonempty && [comments sortByCreatedAt:NO]) {
        self.comments = comments;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self editPicture:[dictionary stringForKey:WLCandyXLargeURLKey]
                   medium:[dictionary stringForKey:WLCandyXMediumURLKey]
                    small:[dictionary stringForKey:WLCandyXSmallURLKey]];
    } else {
        [self editPicture:[dictionary stringForKey:WLCandyLargeURLKey]
                   medium:[dictionary stringForKey:WLCandyMediumURLKey]
                    small:[dictionary stringForKey:WLCandySmallURLKey]];
    }
    
    WLWrap* currentWrap = self.wrap;
    WLWrap* wrap = relatedEntry ? : (currentWrap ? : [WLWrap entry:[dictionary stringForKey:WLWrapUIDKey]]);
    if (wrap != currentWrap) self.wrap = wrap;
    return self;
}

- (void)touch:(NSDate *)date {
    [super touch:date];
    WLWrap* wrap = self.wrap;
    [wrap touch:date];
    [wrap sortCandies];
}

- (BOOL)isCandyOfType:(NSInteger)type {
    return [self.type isEqualToInteger:type];
}

- (BOOL)belongsToWrap:(WLWrap *)wrap {
    return self.wrap == wrap;
}

- (void)remove {
    [self.wrap removeCandy:self];
    [self notifyOnDeleting];
    [super remove];
}

- (void)addComment:(WLComment *)comment {
    NSMutableOrderedSet* comments = self.comments;
    if (!comment || [comments containsObject:comment]) {
        if ([comments sortByCreatedAt:NO]) {
            self.comments = comments;
        }
        return;
    }
    comment.candy = self;
    [comments addObject:comment comparator:comparatorByCreatedAt descending:NO];
    [self touch];
    [comment notifyOnAddition];
}

- (void)removeComment:(WLComment *)comment {
    NSMutableOrderedSet* comments = self.comments;
    if ([comments containsObject:comment]) {
        [comments removeObject:comment];
        self.comments = comments;
    }
}

- (void)uploadComment:(NSString *)text success:(WLCommentBlock)success failure:(WLFailureBlock)failure {
    WLComment* comment = [WLComment comment:text];
    [self addComment:comment];
    WLUploading* uploading = [WLUploading uploading:comment];
    run_after(0.3f,^{
        [uploading upload:success failure:failure];
    });
}

- (BOOL)canBeUploaded {
    return self.wrap.uploading == nil;
}

- (WLEntry *)containingEntry {
    return self.wrap;
}

- (void)setContainingEntry:(WLEntry *)containingEntry {
    if (containingEntry && self.wrap != containingEntry) {
        self.wrap = (id)containingEntry;
    }
}

- (void)enqueueUnuploadedComments {
    [self.comments enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(WLComment* comment, NSUInteger idx, BOOL *stop) {
        if (comment.status == WLContributionStatusReady) {
            [WLUploading enqueueAutomaticUploading];
            *stop = YES;
        }
    }];
}

@end

