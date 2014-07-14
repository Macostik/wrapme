//
//  WLWrap.h
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrap.h"
#import "WLBlocks.h"

static NSUInteger WLWrapNameLimit = 190;

@interface WLWrap (Extended)

+ (instancetype)wrap;

- (NSString*)contributorNames;

- (void)addCandy:(WLCandy *)candy;

- (void)addCandies:(NSOrderedSet *)candies;

- (void)removeCandy:(WLCandy *)candy;

- (BOOL)containsCandy:(WLCandy *)candy;

- (void)sortCandies;

- (NSOrderedSet *)candiesOfType:(NSInteger)type maximumCount:(NSUInteger)maximumCount;

- (NSOrderedSet*)candies:(NSUInteger)maximumCount;

- (NSOrderedSet*)images:(NSUInteger)maximumCount;

- (NSOrderedSet*)messages:(NSUInteger)maximumCount;

- (NSOrderedSet*)images;

- (NSOrderedSet*)messages;

- (NSOrderedSet*)recentCandies:(NSUInteger)maximumCount;

- (void)uploadMessage:(NSString*)message success:(WLCandyBlock)success failure:(WLFailureBlock)failure;

- (void)uploadPicture:(WLPicture *)picture success:(WLCandyBlock)success failure:(WLFailureBlock)failure;

- (void)uploadPicture:(WLPicture *)picture;

- (void)uploadPictures:(NSArray *)pictures;

- (void)uploadImage:(UIImage *)image success:(WLCandyBlock)success failure:(WLFailureBlock)failure;

@end
