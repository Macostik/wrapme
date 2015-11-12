//
//  WLImageCache.m
//  meWrap
//
//  Created by Ravenpod on 29.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLImageCache.h"
#import <ImageIO/ImageIO.h>
#import "WLSystemImageCache.h"
#import "GCDHelper.h"
#import <CommonCrypto/CommonCrypto.h>
#import <objc/runtime.h>

static NSUInteger WLImageCacheSize = 524288000;

@interface WLImageCache ()

@end

@implementation WLImageCache

+ (instancetype)defaultCache {
    static WLImageCache *instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] initWithIdentifier:@"wl_ImagesCache"];
        instance.size = WLImageCacheSize;
	});
    return instance;
}

+ (instancetype)uploadingCache {
    static WLImageCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initWithIdentifier:@"wl_UploadingImagesCache"];
        instance.compressionQuality = 0.75f;
        instance.size = 0;
    });
    return instance;
}

- (void)configure {
    self.compressionQuality = 1.0f;
    [super configure];
}

- (id)read:(NSString *)identifier {
    if (!self.permitted) {
        return [WLSystemImageCache imageWithIdentifier:identifier];
    }
    UIImage* image = [WLSystemImageCache imageWithIdentifier:identifier];
    if (image == nil) {
        image = [UIImage imageWithContentsOfFile:[self pathWithIdentifier:identifier]];
        [WLSystemImageCache setImage:image withIdentifier:identifier];
    }
    return image;
}

- (void)write:(NSString *)identifier object:(id)image {
    if (image && identifier.nonempty) {
        if (self.permitted) {
            NSData *imageData = UIImageJPEGRepresentation(image, self.compressionQuality);
            if ([imageData length] > 0) {
                [imageData writeToFile:[self pathWithIdentifier:identifier] atomically:NO];
            }
        }
        [WLSystemImageCache setImage:image withIdentifier:identifier];
    }
}

- (BOOL)containsObjectWithIdentifier:(NSString *)identifier {
	if ([WLSystemImageCache imageWithIdentifier:identifier] != nil) {
		return YES;
	}
    if (self.permitted) {
        return [super containsObjectWithIdentifier:identifier];
    } else {
        return NO;
    }
}

- (UIImage*)imageWithIdentifier:(NSString*)identifier {
	return [self objectWithIdentifier:identifier];
}

- (void)imageWithIdentifier:(NSString *)identifier completion:(void (^)(UIImage *image, BOOL cached))completion {
	UIImage* image = [WLSystemImageCache imageWithIdentifier:identifier];
	if (image != nil || !self.permitted) {
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
	[self setImage:image withIdentifier:[[NSString GUID] stringByAppendingPathExtension:@"jpg"] completion:completion];
}

- (NSString *)setImage:(UIImage *)image {
    NSString *identifier = [[NSString GUID] stringByAppendingPathExtension:@"jpg"];
    [self write:identifier object:image];
    [self.identifiers addObject:identifier];
    return identifier;
}

- (void)setImageAtPath:(NSString *)path withIdentifier:(NSString *)identifier {
	if (self.permitted && identifier.nonempty && path.nonempty && [path isExistingFilePath]) {
        NSString *toPath = [self pathWithIdentifier:identifier];
        NSError *error = nil;
        if ([[NSFileManager defaultManager] copyItemAtPath:path toPath:toPath error:&error]) {
            UIImage* image = [WLSystemImageCache imageWithIdentifier:path];
            if (image != nil) {
                [WLSystemImageCache removeImageWithIdentifier:path];
            }
            image = [UIImage imageWithData:[[NSFileManager defaultManager] contentsAtPath:toPath]];
            [WLSystemImageCache setImage:image withIdentifier:identifier];
            [self.identifiers addObject:identifier];
            run_after_asap(^{
                [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
            });
        }
    }
}

- (void)setImageData:(NSData*)data withIdentifier:(NSString*)identifier completion:(void (^)(NSString* identifier))completion {
	if (!data || !self.permitted) {
		return;
	}
	dispatch_async(self.queue, ^{
        if (identifier) {
            [data writeToFile:[self pathWithIdentifier:identifier] atomically:NO];
            run_in_main_queue(^{
                [self.identifiers addObject:identifier];
                if (completion) completion(identifier);
                [self enqueueCheckSizePerforming];
            });
        }
    });
}

- (void)setImageData:(NSData*)data withIdentifier:(NSString*)identifier {
    if (!identifier || !data || !self.permitted) {
        return;
    }
    [data writeToFile:[self pathWithIdentifier:identifier] atomically:NO];
    [self.identifiers addObject:identifier];
    [self enqueueCheckSizePerforming];
}

- (void)setImageData:(NSData*)data completion:(void (^)(NSString* path))completion {
	[self setImageData:data withIdentifier:[[NSString GUID] stringByAppendingPathExtension:@"jpg"] completion:completion];
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

@implementation NSString (MD5)

- (NSString*)MD5 {
    NSString* MD5 = [self associatedObjectForKey:"MD5"];
    if (!MD5) {
        const char *ptr = [self UTF8String];
        unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
        CC_MD5(ptr, (CC_LONG)strlen(ptr), md5Buffer);
        NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
        for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
            [output appendFormat:@"%02x",md5Buffer[i]];
        MD5 = output;
        [self setAssociatedObject:MD5 forKey:"MD5"];
    }
    return MD5;
}

@end
