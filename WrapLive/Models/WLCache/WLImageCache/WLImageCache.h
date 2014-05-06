//
//  WLImageCache.h
//  WrapLive
//
//  Created by Sergey Maximenko on 29.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCache.h"

UIImage* WLThumbnailFromUrl(NSString* imageUrl, CGFloat size);

UIImage* WLImageFromUrl(NSString* imageUrl);

@interface WLImageCache : WLCache

+ (instancetype)uploadingCache;

- (UIImage*)imageWithIdentifier:(NSString*)identifier;

- (void)imageWithIdentifier:(NSString*)identifier completion:(void (^)(UIImage* image))completion;

- (void)setImage:(UIImage*)image withIdentifier:(NSString*)identifier completion:(void (^)(NSString* path))completion;

- (void)setImage:(UIImage*)image completion:(void (^)(NSString* path))completion;

- (void)setImageAtPath:(NSString*)path withIdentifier:(NSString*)identifier;

@end

@interface WLImageCache (UrlCache)

- (UIImage*)imageWithUrl:(NSString*)url;

- (void)imageWithUrl:(NSString*)url completion:(void (^)(UIImage* image))completion;

- (void)setImage:(UIImage*)image withUrl:(NSString*)url;

- (BOOL)containsImageWithUrl:(NSString*)url;

- (void)setImageAtPath:(NSString*)path withUrl:(NSString*)url;

@end
