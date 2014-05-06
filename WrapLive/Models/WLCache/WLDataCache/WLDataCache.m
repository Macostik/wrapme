//
//  WLCache.m
//  WrapLive
//
//  Created by Sergey Maximenko on 28.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLDataCache.h"
#import "WLArchivingObject.h"
#import "NSString+Documents.h"

static NSString* WLDataCacheWrapsIdentifier = @"mainScreenWraps";

static NSString* WLDataCacheUploadingItemsIdentifier = @"uploadingItems";

static NSUInteger WLWrapCacheSize = 104857600;

@interface WLDataCache ()

@property (strong, nonatomic) WLCache* wrapsCache;

@property (strong, nonatomic) WLCache* candiesCache;

@end

@implementation WLDataCache

+ (instancetype)cache {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [self cacheWithIdentifier:@"wl_DataCache"];
	});
    return instance;
}

- (void)setWraps:(NSArray *)wraps {
	[self setObject:wraps withIdentifier:WLDataCacheWrapsIdentifier];
}

- (void)setWraps:(NSArray *)wraps completion:(WLCacheWriteCompletionBlock)completion {
	[self setObject:wraps withIdentifier:WLDataCacheWrapsIdentifier completion:completion];
}

- (NSArray *)wraps {
	return [self objectWithIdentifier:WLDataCacheWrapsIdentifier];
}

- (void)wraps:(WLCacheReadCompletionBlock)completion {
	[self objectWithIdentifier:WLDataCacheWrapsIdentifier completion:completion];
}

- (void)setUploadingItems:(NSArray *)uploadingItems {
	[self setObject:uploadingItems withIdentifier:WLDataCacheUploadingItemsIdentifier];
}

- (NSArray *)uploadingItems {
	return [self objectWithIdentifier:WLDataCacheUploadingItemsIdentifier];
}

- (void)uploadingItems:(WLCacheReadCompletionBlock)completion {
	[self objectWithIdentifier:WLDataCacheUploadingItemsIdentifier completion:completion];
}

- (BOOL)containsWraps {
	return [self containsObjectWithIdentifier:WLDataCacheWrapsIdentifier];
}

- (BOOL)containsUploadingItems {
	return [self containsObjectWithIdentifier:WLDataCacheUploadingItemsIdentifier];
}

- (WLCache *)wrapsCache {
	if (!_wrapsCache) {
		_wrapsCache = [WLCache cacheWithIdentifier:@"wraps" relativeCache:self];
		_wrapsCache.size = WLWrapCacheSize;
	}
	return _wrapsCache;
}

- (WLCache *)candiesCache {
	if (!_candiesCache) {
		_candiesCache = [WLCache cacheWithIdentifier:@"candies" relativeCache:self];
		_candiesCache.size = WLWrapCacheSize;
	}
	return _candiesCache;
}

- (WLWrap*)wrap:(WLWrap *)wrap {
	WLCache* wrapCache = [WLCache cacheWithIdentifier:wrap.identifier relativeCache:self.wrapsCache];
	return [wrapCache objectWithIdentifier:@"wrapObject"];
}

- (void)setWrap:(WLWrap*)wrap {
	WLCache* wrapCache = [WLCache cacheWithIdentifier:wrap.identifier relativeCache:self.wrapsCache];
	[wrapCache setObject:wrap withIdentifier:@"wrapObject"];
	[self.wrapsCache enqueueCheckSizePerforming];
}

- (BOOL)containsWrap:(WLWrap *)wrap {
	return [self.wrapsCache containsObjectWithIdentifier:wrap.identifier];
}

- (void)setCandy:(WLCandy*)candy {
	[self.candiesCache setObject:candy withIdentifier:candy.identifier];
}

- (WLCandy*)candy:(WLCandy*)candy{
	return [self.candiesCache objectWithIdentifier:candy.identifier];
}

- (BOOL)containsCandy:(WLCandy *)candy {
	return [self.candiesCache containsObjectWithIdentifier:candy.identifier];
}

- (void)setMessages:(NSArray*)messages wrap:(WLWrap*)wrap {
	WLCache* wrapCache = [WLCache cacheWithIdentifier:wrap.identifier relativeCache:self.wrapsCache];
	[wrapCache setObject:messages withIdentifier:@"messages"];
}

- (NSArray*)messages:(WLWrap*)wrap {
	WLCache* wrapCache = [WLCache cacheWithIdentifier:wrap.identifier relativeCache:self.wrapsCache];
	return [wrapCache objectWithIdentifier:@"messages"];
}

- (BOOL)containsMessages:(WLWrap *)wrap {
	WLCache* wrapCache = [WLCache cacheWithIdentifier:wrap.identifier relativeCache:self.wrapsCache];
	return [wrapCache containsObjectWithIdentifier:@"messages"];
}

@end

@implementation WLWrap (WLDataCache)

- (void)cache {
	[[WLDataCache cache] setWrap:self];
}

@end

@implementation WLCandy (WLDataCache)

- (void)cache {
	[[WLDataCache cache] setCandy:self];
}

@end
