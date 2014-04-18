//
//  UIImageView+ImageLoading.m
//  WrapLive
//
//  Created by Sergey Maximenko on 31.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIImageView+ImageLoading.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "UIImage+Resize.h"
#import "UIView+Shorthand.h"
#import <ImageIO/ImageIO.h>
#import "AsynchronousOperation.h"
#import <objc/runtime.h>
#import "UIImage+WLStoring.h"

@interface UIImageView ()

@property (strong, nonatomic) AsynchronousOperation* fileSystemOperation;

@end

@implementation UIImageView (ImageLoading)

@dynamic imageUrl;

- (void)setImageUrl:(NSString *)imageUrl {
	[self setImageUrl:imageUrl completion:nil];
}

- (void)setImageUrl:(NSString *)imageUrl completion:(void (^)(UIImage* image, BOOL cached))completion {
	self.image = nil;
	[self.fileSystemOperation cancel];
	if ([[NSFileManager defaultManager] fileExistsAtPath:imageUrl]) {
		[self setFileSystemImageUrl:imageUrl completion:completion];
	} else {
		[self setNetworkImageUrl:imageUrl completion:completion];
	}
}

- (void)setNetworkImageUrl:(NSString *)imageUrl completion:(void (^)(UIImage* image, BOOL cached))completion {
	NSURL* url = [NSURL URLWithString:imageUrl];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
	__weak typeof(self)weakSelf = self;
	[self setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
		[weakSelf setImage:image animated:(request != nil)];
		if (completion) {
			completion(image, request == nil);
		}
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
		if (completion) {
			completion(nil, NO);
		}
	}];
}

- (void)setFileSystemImageUrl:(NSString *)imageUrl completion:(void (^)(UIImage* image, BOOL cached))completion {
	[self cancelImageRequestOperation];
	__weak typeof(self)weakSelf = self;
	self.fileSystemOperation = [[NSOperationQueue mainQueue] addAsynchronousOperationWithBlock:^(AsynchronousOperation *operation) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			UIImage* image = [[UIImageView fileSystemImagesCache] objectForKey:imageUrl];
			BOOL animated = NO;
			if (!image) {
				image = [UIImageView thumbnailFromUrl:imageUrl size:100];
				if (image && imageUrl) {
					[[UIImageView fileSystemImagesCache] setObject:image forKey:imageUrl];
				}
				animated = YES;
			}
			
			dispatch_async(dispatch_get_main_queue(), ^{
				if (![operation isCancelled]) {
					[weakSelf setImage:image animated:animated];
					if (completion) {
						completion(image, YES);
					}
				}
				[operation finish];
			});
		});
	}];
}

+ (NSCache*)fileSystemImagesCache {
	static NSCache* _fileSystemImagesCache = nil;
	if (!_fileSystemImagesCache) {
		_fileSystemImagesCache = [[NSCache alloc] init];
	}
	return _fileSystemImagesCache;
}

+ (UIImage*)thumbnailFromUrl:(NSString*)imageUrl size:(CGFloat)size {
	UIImage* image = nil;
	NSURL* url = [NSURL fileURLWithPath:imageUrl];
	CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)(url), NULL);
	if (source != NULL) {
		NSDictionary* options = @{(id)kCGImageSourceShouldCache:@YES,
								  (id)kCGImageSourceThumbnailMaxPixelSize:@(size),
								  (id)kCGImageSourceCreateThumbnailFromImageIfAbsent:@YES,
								  (id)kCGImageSourceCreateThumbnailWithTransform:@YES};
		CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)(options));
		image = [UIImage imageWithCGImage:imageRef];
		
		CGImageRelease(imageRef);
		CFRelease(source);
	}
	return image;
}

- (void)setFileSystemOperation:(AsynchronousOperation *)fileSystemOperation {
	objc_setAssociatedObject(self, "fileSystemOperation", fileSystemOperation, OBJC_ASSOCIATION_RETAIN);
}

- (AsynchronousOperation *)fileSystemOperation {
	return objc_getAssociatedObject(self, "fileSystemOperation");
}

- (void)setImage:(UIImage *)image animated:(BOOL)animated {
	if (animated) {
		CATransition* fadeTransition = [CATransition animation];
		fadeTransition.duration = 0.3;
		fadeTransition.type = kCATransitionFade;
		[self.layer addAnimation:fadeTransition forKey:nil];
	}
	self.image = image;
}

@end
