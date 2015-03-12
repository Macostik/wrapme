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

@interface WLImageCache ()

@end

@implementation WLImageCache

+ (instancetype)cache {
    static WLImageCache *instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [self cacheWithIdentifier:@"wl_ImagesCache"];
        instance.size = WLImageCacheSize;
	});
    return instance;
}

+ (instancetype)uploadingCache {
    static WLImageCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self cacheWithIdentifier:@"wl_UploadingImagesCache"];
        instance.size = 0;
    });
    return instance;
}

- (void)configure {
    self.compressionQuality = 1.0f;
    [super configure];
}

- (id)read:(NSString *)identifier {
    UIImage* image = [WLSystemImageCache imageWithIdentifier:identifier];
    if (image == nil) {
        image = [UIImage imageWithContentsOfFile:[self pathWithIdentifier:identifier]];
        [WLSystemImageCache setImage:image withIdentifier:identifier];
    }
    return image;
}

- (void)write:(NSString *)identifier object:(id)image {
    if (image && identifier.nonempty) {
        NSData *imageData = UIImageJPEGRepresentation(image, self.compressionQuality);
        if ([imageData length] > 0) {
            [imageData writeToFile:[self pathWithIdentifier:identifier] atomically:NO];
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
	if (identifier.nonempty && path.nonempty && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *toPath = [self pathWithIdentifier:identifier];
        [[NSFileManager defaultManager] moveItemAtPath:path toPath:toPath error:NULL];
        UIImage* image = [WLSystemImageCache imageWithIdentifier:path];
        if (image == nil) {
            image = [UIImage imageWithData:[[NSFileManager defaultManager] contentsAtPath:toPath]];
        } else {
            [WLSystemImageCache removeImageWithIdentifier:path];
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
        [data writeToFile:[self pathWithIdentifier:identifier] atomically:NO];
        [self.identifiers addObject:identifier];
		run_in_main_queue(^{
			if (completion) completion(identifier);
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
