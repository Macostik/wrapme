//
//  WLCache.h
//  WrapLive
//
//  Created by Sergey Maximenko on 28.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCache.h"
#import "WLWrap.h"
#import "WLCandy.h"

@protocol WLDataCaching <NSObject>

- (void)cache;

@end

@interface WLDataCache : WLCache

@property (nonatomic) NSArray* wraps;

@property (nonatomic) NSArray* uploadings;

- (void)wraps:(WLCacheReadCompletionBlock)completion;

- (void)setWraps:(NSArray *)wraps completion:(WLCacheWriteCompletionBlock)completion;

- (void)uploadings:(WLCacheReadCompletionBlock)completion;

- (BOOL)containsWraps;

- (BOOL)containsUploadingItems;

- (WLWrap*)wrap:(WLWrap*)wrap;

- (void)setWrap:(WLWrap*)wrap;

- (BOOL)containsWrap:(WLWrap*)wrap;

- (void)setCandy:(WLCandy*)candy;

- (WLCandy*)candy:(WLCandy*)candy;

- (BOOL)containsCandy:(WLCandy*)candy;

- (void)setMessages:(NSArray*)messages wrap:(WLWrap*)wrap;

- (NSArray*)messages:(WLWrap*)wrap;

- (BOOL)containsMessages:(WLWrap*)wrap;

@end

@interface WLWrap (WLDataCache) <WLDataCaching>

@end

@interface WLCandy (WLDataCache) <WLDataCaching>

@end
