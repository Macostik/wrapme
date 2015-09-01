//
//  WLCandy.h
//  CoreData1
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandy.h"

static NSInteger WLCandyTypeImage = 10;

@interface WLCandy (Extended)

+ (instancetype)candyWithType:(NSInteger)type wrap:(WLWrap*)wrap;

- (void)addComment:(WLComment *)comment;

- (void)removeComment:(WLComment *)comment;

- (id)uploadComment:(NSString *)text success:(WLCommentBlock)success failure:(WLFailureBlock)failure;

- (void)download:(WLBlock)success failure:(WLFailureBlock)failure;

- (NSMutableOrderedSet *)sortedComments;

- (WLComment*)latestComment;

- (void)setEditedPictureIfNeeded:(WLPicture *)editedPicture;

- (void)editWithImage:(UIImage*)image;

@end
