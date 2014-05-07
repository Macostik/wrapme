//
//  WLCache.h
//  WrapLive
//
//  Created by Sergey Maximenko on 30.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^WLCacheReadObjectBlock)(NSString* identifier, NSString* path);
typedef void (^WLCacheWriteObjectBlock)(NSString* identifier, id object, NSString* path);
typedef void (^WLCacheReadCompletionBlock)(id object);
typedef void (^WLCacheWriteCompletionBlock)(NSString* path);

@interface WLCache : NSObject

@property (strong, nonatomic, readonly) NSString* identifier;

@property (nonatomic, readonly) NSString* directory;

@property (strong, nonatomic) WLCacheReadObjectBlock readObjectBlock;

@property (strong, nonatomic) WLCacheWriteObjectBlock writeObjectBlock;

@property (nonatomic) NSUInteger size;

@property (nonatomic, readonly) NSFileManager* manager;

+ (instancetype)cache;

+ (instancetype)cacheWithIdentifier:(NSString*)identifier;

+ (instancetype)cacheWithIdentifier:(NSString*)identifier relativeCache:(WLCache*)relativeCache;

- (void)configure;

- (NSString*)pathWithIdentifier:(NSString*)identifier;

- (BOOL)containsObjectWithIdentifier:(NSString*)identifier;

- (id)objectWithIdentifier:(NSString*)identifier;

- (void)objectWithIdentifier:(NSString*)identifier completion:(WLCacheReadCompletionBlock)completion;

- (void)setObject:(id)object withIdentifier:(NSString*)identifier completion:(WLCacheWriteCompletionBlock)completion;

- (void)setObject:(id)object withIdentifier:(NSString*)identifier;

- (void)clear;

- (void)enqueueCheckSizePerforming;

@end
