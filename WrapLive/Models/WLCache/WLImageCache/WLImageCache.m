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
#import "NSString+Additions.h"
#import "WLSystemImageCache.h"
#import "UIDevice+SystemVersion.h"

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

- (void)configure {
	self.size = WLImageCacheSize;
	[super configure];
}

- (id)read:(NSString *)identifier {
    UIImage* image = [WLSystemImageCache imageWithIdentifier:identifier];
    if (image == nil) {
        image = [UIImage imageWithData:[_manager contentsAtPath:identifier]];
        [WLSystemImageCache setImage:image withIdentifier:identifier];
    }
    return image;
}

- (void)write:(NSString *)identifier object:(id)image {
    if (image && identifier.nonempty) {
        NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
        if ([imageData length] > 0) {
            if (SystemVersionGreaterThanOrEqualTo8()) {
                [imageData writeToFile:[[_manager currentDirectoryPath] stringByAppendingPathComponent:identifier] atomically:YES];
            } else {
                [_manager createFileAtPath:identifier contents:imageData attributes:nil];
            }
            [WLSystemImageCache setImage:image withIdentifier:identifier];
        }
    }
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

- (void)imageWithIdentifier:(NSString *)identifier completion:(void (^)(UIImage *image, BOOL cached))completion {
	UIImage* image = [WLSystemImageCache imageWithIdentifier:identifier];
	if (image != nil) {
		completion(image, YES);
		return;
	}
	[self objectWithIdentifier:identifier completion:^(id object) {
        if (completion) {
            completion(object, NO);
        }
    }];
}

- (void)setImage:(UIImage*)image withIdentifier:(NSString*)identifier completion:(void (^)(NSString *identifier))completion {
	[self setObject:image withIdentifier:identifier completion:completion];
}

- (void)setImage:(UIImage *)image completion:(void (^)(NSString *))completion {
	[self setImage:image withIdentifier:[GUID() stringByAppendingPathExtension:@"jpg"] completion:completion];
}

- (void)setImageAtPath:(NSString *)path withIdentifier:(NSString *)identifier {
	if (identifier.nonempty && path.nonempty && [_manager fileExistsAtPath:path]) {
        [_manager moveItemAtPath:path toPath:identifier error:NULL];
        UIImage* image = [WLSystemImageCache imageWithIdentifier:[path lastPathComponent]];
        if (image == nil) {
            image = [UIImage imageWithData:[_manager contentsAtPath:identifier]];
        } else {
            [WLSystemImageCache removeImageWithIdentifier:[path lastPathComponent]];
        }
        [WLSystemImageCache setImage:image withIdentifier:identifier];
        [self.identifiers addObject:identifier];
	}
}

- (void)setImageData:(NSData*)data withIdentifier:(NSString*)identifier completion:(void (^)(NSString* identifier))completion {
	if (!data) {
		return;
	}
	dispatch_async(self.queue, ^{
        if (SystemVersionGreaterThanOrEqualTo8()) {
            [data writeToFile:[[_manager currentDirectoryPath] stringByAppendingPathComponent:identifier] atomically:YES];
        } else {
            [_manager createFileAtPath:identifier contents:data attributes:nil];
        }
        [self.identifiers addObject:identifier];
		run_in_main_queue(^{
			if (completion) {
				completion(identifier);
			}
            [self enqueueCheckSizePerforming];
		});
		
    });
}

- (void)setImageData:(NSData*)data completion:(void (^)(NSString* path))completion {
	[self setImageData:data withIdentifier:[GUID() stringByAppendingPathExtension:@"jpg"] completion:completion];
}

@end

@implementation WLImageCache (UrlCache)

- (UIImage*)imageWithUrl:(NSString*)url {
	return [self imageWithIdentifier:[self identifierFromUrl:url]];
}

- (void)imageWithUrl:(NSString *)url completion:(void (^)(UIImage *, BOOL cached))completion {
	return [self imageWithIdentifier:[self identifierFromUrl:url] completion:completion];
}

- (void)setImage:(UIImage*)image withUrl:(NSString*)url {
	[self setImage:image withIdentifier:[self identifierFromUrl:url] completion:nil];
}

- (BOOL)containsImageWithUrl:(NSString *)url {
	return [self containsObjectWithIdentifier:[self identifierFromUrl:url]];
}

- (void)setImageAtPath:(NSString*)path withUrl:(NSString*)url {
	if (url.nonempty) {
		[self setImageAtPath:path withIdentifier:[self identifierFromUrl:url]];
	}
}

- (void)setImageAtPath:(NSString *)path withUrl:(NSString *)url completion:(void (^)(void))completion {
	__weak typeof(self)weakSelf = self;
	run_with_completion(^{
		[weakSelf setImageAtPath:path withUrl:url];
	}, completion);
}

- (NSString*)identifierFromUrl:(NSString*)url {
    if ([url isAbsolutePath]) {
        return [url lastPathComponent];
    } else {
        return [[url MD5] stringByAppendingPathExtension:@"jpg"];
    }
}

@end
