//
//  WLCache.h
//  moji
//
//  Created by Ravenpod on 30.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^WLCacheReadCompletionBlock)(id object);
typedef void (^WLCacheWriteCompletionBlock)(NSString* identifier);

@interface WLCache : NSObject

@property (nonatomic) BOOL permitted;

@property (strong, nonatomic, readonly) NSString* identifier;

@property (nonatomic, strong) NSString* directory;

@property (nonatomic) NSUInteger size;

@property (strong, nonatomic) dispatch_queue_t queue;

@property (strong, nonatomic) NSMutableSet* identifiers;

+ (instancetype)cache;

+ (instancetype)cacheWithIdentifier:(NSString*)identifier;

+ (instancetype)cacheWithIdentifier:(NSString*)identifier relativeCache:(WLCache*)relativeCache;

- (void)configure;

- (id)read:(NSString*)identifier;

- (void)write:(NSString*)identifier object:(id)object;

- (NSString*)pathWithIdentifier:(NSString*)identifier;

- (BOOL)containsObjectWithIdentifier:(NSString*)identifier;

- (id)objectWithIdentifier:(NSString*)identifier;

- (void)objectWithIdentifier:(NSString*)identifier completion:(WLCacheReadCompletionBlock)completion;

- (void)setObject:(id)object withIdentifier:(NSString*)identifier completion:(WLCacheWriteCompletionBlock)completion;

- (void)setObject:(id)object withIdentifier:(NSString*)identifier;

- (void)clear;

- (void)enqueueCheckSizePerforming;

- (void)checkSizeAndClearIfNeededInBackground;

- (void)fetchIdentifiers;

@end
