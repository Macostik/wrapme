//
//  WLWrap.h
//  CoreData1
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWrap.h"

static NSUInteger WLWrapNameLimit = 190;

@interface WLWrap (Extended)

@property (nonatomic, readonly) BOOL isFirstCreated;

@property (readonly, nonatomic) BOOL requiresFollowing;

@property (readonly, nonatomic) BOOL isContributing;

+ (instancetype)wrap;

- (NSString*)contributorNames;

- (void)uploadMessage:(NSString*)text success:(WLMessageBlock)success failure:(WLFailureBlock)failure;

- (void)uploadPicture:(WLPicture *)picture success:(WLCandyBlock)success failure:(WLFailureBlock)failure;

- (void)uploadPicture:(WLPicture *)picture;

- (void)uploadPictures:(NSArray *)pictures start:(WLBlock)start finish:(WLBlock)finish;

- (void)uploadPictures:(NSArray *)pictures;

- (BOOL)isFirstCreated;

@end
