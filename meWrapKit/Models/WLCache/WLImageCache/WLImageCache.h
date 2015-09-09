//
//  WLImageCache.h
//  meWrap
//
//  Created by Ravenpod on 29.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLCache.h"

@interface WLImageCache : WLCache

@property (nonatomic) CGFloat compressionQuality;

+ (instancetype)uploadingCache;

- (UIImage*)imageWithIdentifier:(NSString*)identifier;

- (void)imageWithIdentifier:(NSString*)identifier completion:(void (^)(UIImage* image, BOOL cached))completion;

- (void)setImage:(UIImage*)image withIdentifier:(NSString*)identifier completion:(WLCacheWriteCompletionBlock)completion;

- (void)setImage:(UIImage*)image completion:(void (^)(NSString* path))completion;

- (void)setImageAtPath:(NSString*)path withIdentifier:(NSString*)identifier;

- (void)setImageData:(NSData*)data withIdentifier:(NSString*)identifier completion:(WLCacheWriteCompletionBlock)completion;

- (void)setImageData:(NSData*)data completion:(void (^)(NSString* path))completion;

@end

@interface WLImageCache (UrlCache)

- (UIImage*)imageWithUrl:(NSString*)url;

- (void)imageWithUrl:(NSString*)url completion:(void (^)(UIImage* image, BOOL cached))completion;

- (void)setImage:(UIImage*)image withUrl:(NSString*)url;

- (BOOL)containsImageWithUrl:(NSString*)url;

- (void)setImageAtPath:(NSString*)path withUrl:(NSString*)url;

- (void)setImageAtPath:(NSString*)path withUrl:(NSString*)url completion:(void (^)(void))completion;

@end
