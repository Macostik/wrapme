//
//  WLCandy.m
//  CoreData1
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandy+Extended.h"
#import "WLEntryManager.h"
#import "WLEntryNotifier.h"
#import "NSString+Additions.h"
#import "WLImageCache.h"
#import "UIImage+Drawing.h"
#import "NSError+WLAPIManager.h"
#import "WLBlockImageFetching.h"
#import "WLEntry+WLAPIRequest.h"
#import "GCDHelper.h"
#import "WLLocalization.h"

@import Photos;

@implementation WLCandy (Extended)

+ (NSNumber *)uploadingOrder {
    return @2;
}

+ (instancetype)candyWithType:(NSInteger)type wrap:(WLWrap*)wrap {
    WLCandy* candy = [self contribution];
    candy.type = type;
    return candy;
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return [dictionary stringForKey:WLCandyUIDKey];
}

+ (void)API_prefetchDescriptors:(NSMutableDictionary *)descriptors inDictionary:(NSDictionary *)dictionary {
    [super API_prefetchDescriptors:descriptors inDictionary:dictionary];
    if (dictionary[WLCommentsKey]) {
        [WLComment API_prefetchDescriptors:descriptors inArray:dictionary[WLCommentsKey]];
    }
}

- (instancetype)API_setup:(NSDictionary *)dictionary container:(id)container {
    [super API_setup:dictionary container:container];
    NSInteger type = [dictionary integerForKey:WLCandyTypeKey];
    if (self.type != type) self.type = type;
    NSSet *comments = [WLComment API_entries:[dictionary arrayForKey:WLCommentsKey] container:self];
    if (![comments isSubsetOfSet:self.comments]) {
        [self addComments:comments];
    }
    [self editPicture:[self.picture editWithCandyDictionary:dictionary]];
    NSInteger commentCount = [dictionary integerForKey:WLCommentCountKey];
    if (self.commentCount < commentCount) self.commentCount = commentCount;
    self.container = container ? : (self.wrap ? : [WLWrap entry:[dictionary stringForKey:WLWrapUIDKey]]);
    return self;
}

- (WLPicture *)picture {
    if (self.editedPicture) {
        return self.editedPicture;
    }
    [self willAccessValueForKey:@"picture"];
    WLPicture *picture = [self primitiveValueForKey:@"picture"];
    [self didAccessValueForKey:@"picture"];
    return picture;
}

- (void)setEditedPictureIfNeeded:(WLPicture *)editedPicture {
    switch (self.status) {
        case WLContributionStatusReady:
            self.picture = editedPicture;
            break;
        case WLContributionStatusInProgress:
            break;
        case WLContributionStatusFinished:
            [self touch];
            self.editedPicture = editedPicture;
            break;
        default:
            break;
    }
}

- (void)prepareForDeletion {
    [self.wrap removeCandiesObject:self];
    [super prepareForDeletion];
}

- (void)addComment:(WLComment *)comment {
    NSSet* comments = self.comments;
    self.commentCount++;
    if (!comment || [comments containsObject:comment]) {
        return;
    }
    [self addCommentsObject:comment];
    [self touch];
    [comment notifyOnAddition];
}

- (void)removeComment:(WLComment *)comment {
    NSSet* comments = self.comments;
    if ([comments containsObject:comment]) {
        [self removeCommentsObject:comment];
        if (self.commentCount > 0)  self.commentCount--;
    }
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

@end

