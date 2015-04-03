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
#import "WLImageCache.h"
#import "UIImage+Drawing.h"
#import "WLImageFetcher.h"
#import "WLUploadingQueue.h"
#import "NSError+WLAPIManager.h"

@implementation WLCandy (Extended)

+ (NSNumber *)uploadingOrder {
    return @2;
}

+ (instancetype)candyWithType:(NSInteger)type wrap:(WLWrap*)wrap {
    WLCandy* candy = [self contribution];
    candy.type = type;
    [wrap addCandy:candy];
    return candy;
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return [dictionary stringForKey:WLCandyUIDKey];
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    [super API_setup:dictionary relatedEntry:relatedEntry];
    NSInteger type = [dictionary integerForKey:WLCandyTypeKey];
    if (self.type != type) self.type = type;
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
        [self editPicture:[dictionary stringForKey:WLCandyOriginalURLKey]
                    large:[dictionary stringForKey:WLCandyXLargeURLKey]
                   medium:[dictionary stringForKey:WLCandyXMediumURLKey]
                    small:[dictionary stringForKey:WLCandyXSmallURLKey]];
    } else {
        [self editPicture:[dictionary stringForKey:WLCandyOriginalURLKey]
                    large:[dictionary stringForKey:WLCandyLargeURLKey]
                   medium:[dictionary stringForKey:WLCandyMediumURLKey]
                    small:[dictionary stringForKey:WLCandySmallURLKey]];
    }
    NSInteger commentCount = [dictionary integerForKey:WLCommentCountKey];
    if (self.commentCount != commentCount) self.commentCount = commentCount;
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
    return self.type == type;
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
    self.commentCount++;
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
        if (self.commentCount > 0)  self.commentCount--;
        self.comments = comments;
    }
}

- (void)uploadComment:(NSString *)text success:(WLCommentBlock)success failure:(WLFailureBlock)failure {
    WLComment* comment = [WLComment comment:text];
    WLUploading* uploading = [WLUploading uploading:comment];
    [self addComment:comment];
    run_after(0.3f,^{
        [WLUploadingQueue upload:uploading success:success failure:failure];
    });
}

- (BOOL)canBeUploaded {
    return self.wrap.uploading == nil;
}

- (BOOL)deletable {
    return self.contributedByCurrentUser || self.wrap.contributedByCurrentUser;
}

- (WLEntry *)containingEntry {
    return self.wrap;
}

- (void)setContainingEntry:(WLEntry *)containingEntry {
    if (containingEntry && self.wrap != containingEntry) {
        self.wrap = (id)containingEntry;
    }
}

- (void)download:(WLBlock)success failure:(WLFailureBlock)failure {
    
    [self setDownloadSuccessBlock:^(UIImage *image) {
        [image save:nil completion:success failure:failure];
    }];
   
    [self setDownloadFailureBlock:^(NSError *error) {
        if (error.isNetworkError) {
            error = [NSError errorWithDescription:
                     WLLS(@"No internet connections available. Please try downloading it later.")];
        }
        if (failure) {
            failure(error);
        }
    }];
    
    [[WLImageFetcher fetcher] addReceiver:self];
    [[WLImageFetcher fetcher] enqueueImageWithUrl:self.picture.original];
}

// MARK: - WLImageFetching

- (NSString*)fetcherTargetUrl:(WLImageFetcher*)fetcher {
    return self.picture.original;
}

- (void)fetcher:(WLImageFetcher*)fetcher didFinishWithImage:(UIImage*)image cached:(BOOL)cached {
    if (self.downloadSuccessBlock) {
        self.downloadSuccessBlock(image);
        self.downloadSuccessBlock = nil;
    }
    self.downloadFailureBlock = nil;
}

- (void)fetcher:(WLImageFetcher*)fetcher didFailWithError:(NSError*)error {
    if (self.downloadFailureBlock) {
        self.downloadFailureBlock(error);
        self.downloadFailureBlock = nil;
    }
    self.downloadSuccessBlock = nil;
}

- (NSMutableOrderedSet *)sortedComments {
    NSMutableOrderedSet* comments = self.comments;
    [comments sortByCreatedAt];

    return comments;
}

@end

