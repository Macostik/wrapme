//
//  WLWrap.h
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrap.h"

static NSUInteger WLWrapNameLimit = 190;

@interface WLWrap (Extended)

@property (nonatomic, readonly) BOOL isFirstCreated;

+ (instancetype)wrap;

- (NSString*)contributorNames;

- (void)addCandy:(WLCandy *)candy;

- (void)removeCandy:(WLCandy *)candy;

- (void)removeMessage:(WLMessage *)message;

- (BOOL)containsCandy:(WLCandy *)candy;

- (id)uploadMessage:(NSString*)text success:(WLMessageBlock)success failure:(WLFailureBlock)failure;

- (void)uploadPicture:(WLPicture *)picture success:(WLCandyBlock)success failure:(WLFailureBlock)failure;

- (void)uploadPicture:(WLPicture *)picture;

- (void)uploadPictures:(NSArray *)pictures;

- (BOOL)isFirstCreated;

@end
