//
//  WLImageCache.m
//  WrapLive
//
//  Created by Sergey Maximenko on 29.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLImageCache.h"
#import "NSString+Documents.h"
#import "NSString+MD5.h"
#import <ImageIO/ImageIO.h>
#import "NSDictionary+Extended.h"
#import "WLSupportFunctions.h"

UIImage* WLThumbnailFromUrl(NSString* imageUrl, CGFloat size) {
	if (size > 0) {
		size *= [UIScreen mainScreen].scale;
	}
	UIImage* image = nil;
	NSURL* url = [NSURL fileURLWithPath:imageUrl];
	CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)(url), NULL);
	if (source != NULL) {
		NSMutableDictionary* options = [NSMutableDictionary dictionary];
		[options trySetObject:@YES forKey:(id)kCGImageSourceShouldCache];
		if (size > 0) {
			[options trySetObject:@(size) forKey:(id)kCGImageSourceThumbnailMaxPixelSize];
		}
		[options trySetObject:@YES forKey:(id)kCGImageSourceCreateThumbnailFromImageIfAbsent];
		[options trySetObject:@NO forKey:(id)kCGImageSourceCreateThumbnailWithTransform];
		CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)(options));
		image = [UIImage imageWithCGImage:imageRef];
		
		CGImageRelease(imageRef);
		CFRelease(source);
	}
	return image;
}

UIImage* WLImageFromUrl(NSString* imageUrl) {
	NSURL* url = [NSURL fileURLWithPath:imageUrl];
	CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)(url), NULL);
	if (source != NULL) {
		CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, NULL);
		UIImage* image = [UIImage imageWithCGImage:imageRef];
		CGImageRelease(imageRef);
		CFRelease(source);
		return image;
	}
	return nil;
}

@interface WLImageCache ()

@property (strong, nonatomic) NSCache* systemCache;

@end

@implementation WLImageCache

+ (instancetype)cache {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [self cacheWithIdentifier:@"wl_ImagesCache"];
	});
    return instance;
}

+ (instancetype)uploadingCache {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [self cacheWithIdentifier:@"wl_uploadingImagesCache"];
	});
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.readObjectBlock = ^id (NSString* path) {
			return WLImageFromUrl(path);
		};
		self.writeObjectBlock = ^(UIImage* image, NSString* path) {
			[UIImageJPEGRepresentation(image, 1.0f) writeToFile:path atomically:YES];
		};
    }
    return self;
}

- (NSCache *)systemCache {
	if (!_systemCache) {
		_systemCache = [[NSCache alloc] init];
	}
	return _systemCache;
}

- (NSString*)pathWithIdentifier:(NSString*)identifier {
	return [[super pathWithIdentifier:identifier] stringByAppendingPathExtension:@"jpg"];
}

- (BOOL)containsObjectWithIdentifier:(NSString *)identifier {
	if ([self.systemCache objectForKey:identifier] != nil) {
		return YES;
	}
	return [super containsObjectWithIdentifier:identifier];
}

- (UIImage*)imageWithIdentifier:(NSString*)identifier {
	return [self objectWithIdentifier:identifier];
}

- (id)objectWithIdentifier:(NSString *)identifier {
	UIImage* image = [self.systemCache objectForKey:identifier];
	if (image == nil) {
		image = [super objectWithIdentifier:identifier];
		[self.systemCache setObject:image forKey:identifier];
	}
	return image;
}

- (void)imageWithIdentifier:(NSString *)identifier completion:(void (^)(UIImage *))completion {
	UIImage* image = [self.systemCache objectForKey:identifier];
	if (image != nil) {
		completion(image);
		return;
	}
	[self objectWithIdentifier:identifier completion:completion];
}

- (void)setImage:(UIImage*)image withIdentifier:(NSString*)identifier completion:(void (^)(NSString *))completion {
	[self setObject:image withIdentifier:identifier completion:completion];
}

- (void)setImage:(UIImage *)image completion:(void (^)(NSString *))completion {
	[self setImage:image withIdentifier:[NSProcessInfo processInfo].globallyUniqueString completion:completion];
}

@end

@implementation WLImageCache (UrlCache)

- (UIImage*)imageWithUrl:(NSString*)url {
	return [self imageWithIdentifier:[url MD5]];
}

- (void)imageWithUrl:(NSString *)url completion:(void (^)(UIImage *))completion {
	return [self imageWithIdentifier:[url MD5] completion:completion];
}

- (void)setImage:(UIImage*)image withUrl:(NSString*)url {
	[self setImage:image withIdentifier:[url MD5] completion:nil];
}

- (BOOL)containsImageWithUrl:(NSString *)url {
	return [self containsObjectWithIdentifier:[url MD5]];
}

@end
