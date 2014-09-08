//
//  WLCandy.m
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandy+Extended.h"
#import "WLEntryManager.h"
#import "WLWrapBroadcaster.h"
#import "NSString+Additions.h"
#import "WLSupportFunctions.h"

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
    NSMutableOrderedSet* comments = self.comments;
    if (!comments) {
        comments = [NSMutableOrderedSet orderedSet];
        self.comments = comments;
    }
    [WLComment API_entries:[dictionary arrayForKey:WLCommentsKey] relatedEntry:self container:comments];
    if (comments.nonempty) [comments sortByCreatedAtAscending];
    [self editPicture:[dictionary stringForKey:WLCandyLargeURLKey]
               medium:[dictionary stringForKey:WLCandyMediumURLKey]
                small:[dictionary stringForKey:WLCandySmallURLKey]];
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
    [self broadcastRemoving];
    [super remove];
}

- (void)addComment:(WLComment *)comment {
    if (!comment || [self.comments containsObject:comment]) {
        [self.comments sortByCreatedAtAscending];
        return;
    }
    comment.candy = self;
    NSMutableOrderedSet* comments = self.comments;
    [comments addObject:comment];
    [comments sortByCreatedAtAscending];
    [self touch];
    [self broadcastChange];
}

- (void)removeComment:(WLComment *)comment {
    NSMutableOrderedSet* comments = self.comments;
    if ([comments containsObject:comment]) {
        [comments removeObject:comment];
        [self save];
    }
}

- (void)uploadComment:(NSString *)text success:(WLCommentBlock)success failure:(WLFailureBlock)failure {
    WLComment* comment = [WLComment comment:text];
    [self addComment:comment];
    [[WLUploading uploading:comment] upload:success failure:failure];
    [comment save];
}

- (BOOL)canBeUploaded {
    return self.wrap.uploading == nil;
}

@end

