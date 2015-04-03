//
//  WLCandy.h
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandy.h"

static NSInteger WLCandyTypeImage = 10;

@interface WLCandy (Extended)

+ (instancetype)candyWithType:(NSInteger)type wrap:(WLWrap*)wrap;

- (BOOL)isCandyOfType:(NSInteger)type;

- (BOOL)belongsToWrap:(WLWrap *)wrap;

- (void)addComment:(WLComment *)comment;

- (void)removeComment:(WLComment *)comment;

- (void)uploadComment:(NSString *)text success:(WLCommentBlock)success failure:(WLFailureBlock)failure;

- (void)download:(WLBlock)success failure:(WLFailureBlock)failure;

- (NSMutableOrderedSet *)sortedComments;
@end
