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
#import "NSString+Additions.h"
#import "WLSystemImageCache.h"
#import "WLBlocks.h"

static NSUInteger WLImageCacheSize = 524288000;

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
		[options trySetObject:@YES forKey:(id)kCGImageSourceCreateThumbnailWithTransform];
		CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)(options));
		image = [UIImage imageWithCGImage:imageRef];
		
		CGImageRelease(imageRef);
		CFRelease(source);
	}
	return image;
}

@interface WLImageCache ()

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

- (void)configure {
	self.size = WLImageCacheSize;
	
	self.readObjectBlock = ^id (NSString* identifier, NSString* path) {
		UIImage* image = [WLSystemImageCache imageWithIdentifier:identifier];
		if (image == nil) {
			image = [UIImage imageWithContentsOfFile:path];
			[WLSystemImageCache setImage:image withIdentifier:identifier];
		}
		return image;
	};
	
	self.writeObjectBlock = ^(NSString* identifier, id image, NSString* path) {
		if (image) {
			if ([image isKindOfClass:[UIImage class]]) {
				[UIImageJPEGRepresentation(image, 1.0f) writeToFile:path atomically:YES];
			} else if ([image isKindOfClass:[NSData class]]) {
				[image writeToFile:path atomically:YES];
			}
			[WLSystemImageCache setImage:image withIdentifier:identifier];
		}
	};
	
	[super configure];
}

- (NSString*)pathWithIdentifier:(NSString*)identifier {
	return [[super pathWithIdentifier:identifier] stringByAppendingPathExtension:@"jpg"];
}

- (BOOL)containsObjectWithIdentifier:(NSString *)identifier {
	if ([WLSystemImageCache imageWithIdentifier:identifier] != nil) {
		return YES;
	}
	return [super containsObjectWithIdentifier:identifier];
}

- (UIImage*)imageWithIdentifier:(NSString*)identifier {
	return [self objectWithIdentifier:identifier];
}

- (void)imageWithIdentifier:(NSString *)identifier completion:(void (^)(UIImage *))completion {
	UIImage* image = [WLSystemImageCache imageWithIdentifier:identifier];
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
	[self setImage:image withIdentifier:GUID() completion:completion];
}

- (void)setImageAtPath:(NSString *)path withIdentifier:(NSString *)identifier {
	NSFileManager* manager = self.manager;
	if (identifier.nonempty && path.nonempty && [manager fileExistsAtPath:path]) {
		NSString* cachePath = [self pathWithIdentifier:identifier];
		[manager copyItemAtPath:path toPath:cachePath error:NULL];
		[[WLSystemImageCache instance] setImage:[UIImage imageWithContentsOfFile:cachePath] withIdentifier:identifier];
		[manager removeItemAtPath:path error:NULL];
	}
}

- (void)setImageData:(NSData*)data withIdentifier:(NSString*)identifier completion:(void (^)(NSString* path))completion {
	[self setObject:data withIdentifier:identifier completion:completion];
}

- (void)setImageData:(NSData*)data completion:(void (^)(NSString* path))completion {
	[self setImageData:data withIdentifier:GUID() completion:completion];
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

- (void)setImageAtPath:(NSString*)path withUrl:(NSString*)url {
	if (url.nonempty) {
		[self setImageAtPath:path withIdentifier:[url MD5]];
	}
}

- (void)setImageAtPath:(NSString *)path withUrl:(NSString *)url completion:(void (^)(void))completion {
	__weak typeof(self)weakSelf = self;
	run_with_completion(^{
		[weakSelf setImageAtPath:path withUrl:url];
	}, completion);
}

@end
