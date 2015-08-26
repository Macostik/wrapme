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
#import "WLUploadingQueue.h"
#import "NSError+WLAPIManager.h"
#import "ALAssetsLibrary+Additions.h"
#import "WLBlockImageFetching.h"
#import "WLEditPicture.h"
#import "WLEntry+WLAPIRequest.h"

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

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    [super API_setup:dictionary relatedEntry:relatedEntry];
    NSInteger type = [dictionary integerForKey:WLCandyTypeKey];
    if (self.type != type) self.type = type;
    NSSet *comments = [WLComment API_entries:[dictionary arrayForKey:WLCommentsKey] relatedEntry:self];
    if (![comments isSubsetOfSet:self.comments]) {
        [self addComments:comments];
    }
    [self editPicture:[self.picture editWithCandyDictionary:dictionary]];
    NSInteger commentCount = [dictionary integerForKey:WLCommentCountKey];
    if (self.commentCount < commentCount) self.commentCount = commentCount;
    WLWrap* currentWrap = self.wrap;
    WLWrap* wrap = relatedEntry ? : (currentWrap ? : [WLWrap entry:[dictionary stringForKey:WLWrapUIDKey]]);
    if (wrap != currentWrap) self.wrap = wrap;
    
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
    [comment notifyOnAddition:^(id object) {
    }];
}

- (void)removeComment:(WLComment *)comment {
    NSSet* comments = self.comments;
    if ([comments containsObject:comment]) {
        [self removeCommentsObject:comment];
        if (self.commentCount > 0)  self.commentCount--;
    }
}

- (id)uploadComment:(NSString *)text success:(WLCommentBlock)success failure:(WLFailureBlock)failure {
    WLComment* comment = [WLComment comment:text];
    WLUploading* uploading = [WLUploading uploading:comment];
    [self addComment:comment];
    run_after(0.3f,^{
        [WLUploadingQueue upload:uploading success:success failure:failure];
    });
    return comment;
}

- (BOOL)canBeUploaded {
    return self.wrap.uploading == nil;
}

- (BOOL)deletable {
    return self.contributedByCurrentUser || self.wrap.contributedByCurrentUser;
}

- (void)download:(WLBlock)success failure:(WLFailureBlock)failure {
    
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status == ALAuthorizationStatusDenied) {
        if (failure) failure(WLError(WLLS(@"downloading_privacy_settings")));
        return;
    }
    
    [[WLBlockImageFetching fetchingWithUrl:self.picture.original] enqueue:^(UIImage *image) {
        [image save:nil completion:success failure:failure];
    } failure:^(NSError *error) {
        if (error.isNetworkError) {
            error = WLError(WLLS(@"downloading_internet_connection_error"));
        }
        if (failure) failure(error);
    }];
}

- (void)editWithImage:(UIImage*)image {
    if (self.valid) {
        __weak typeof(self)weakSelf = self;
        __block WLEditPicture *picture = [WLEditPicture picture:image completion:^(id object) {
            [weakSelf setEditedPictureIfNeeded:[picture uploadablePicture:NO]];
            [weakSelf enqueueUpdate:^(NSError *error) {
                [error show];
            }];
        }];
    }
}

- (NSMutableOrderedSet *)sortedComments {
    NSMutableOrderedSet* comments = [NSMutableOrderedSet orderedSetWithSet:self.comments];
    [comments sortByCreatedAt];
    return comments;
}

- (WLComment *)latestComment {
    WLComment *comment = [[self sortedComments] firstObject];
    return comment.valid ? comment : nil;
}

@end

