//
//  WLCandy.h
//  CoreData1
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandy.h"

static NSInteger WLCandyTypeImage = 10;
static NSInteger WLCandyTypeVideo = 20;

@interface WLCandy (Extended)

+ (instancetype)candyWithType:(NSInteger)type wrap:(WLWrap*)wrap;

- (void)addComment:(WLComment *)comment;

- (void)removeComment:(WLComment *)comment;

- (NSMutableOrderedSet *)sortedComments;

- (void)setEditedPictureIfNeeded:(WLPicture *)editedPicture;

@end
