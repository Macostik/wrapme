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
#import "WLImageCache.h"

@interface UIImageView ()

@end

@implementation UIImageView (ImageLoading)

@dynamic imageUrl;

- (void)setImageUrl:(NSString *)imageUrl {
	[self setImageUrl:imageUrl completion:nil];
}

- (void)setImageUrl:(NSString *)imageUrl completion:(void (^)(UIImage* image, BOOL cached))completion {
	self.image = nil;
	[self cancelImageRequestOperation];
	if ([[NSFileManager defaultManager] fileExistsAtPath:imageUrl]) {
		[self setFileSystemImageUrl:imageUrl completion:completion];
	} else if ([[WLImageCache cache] containsImageWithUrl:imageUrl]) {
		__weak typeof(self)weakSelf = self;
		[[WLImageCache cache] imageWithUrl:imageUrl completion:^(UIImage *image) {
			weakSelf.image = image;
			if (completion) {
				completion(image, YES);
			}
		}];
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
		[[WLImageCache cache] setImage:image withUrl:imageUrl];
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
		if (error.code != NSURLErrorCancelled) {
			if (completion) {
				completion(nil, NO);
			}
		}
	}];
}

- (void)setFileSystemImageUrl:(NSString *)imageUrl completion:(void (^)(UIImage* image, BOOL cached))completion {
	[self cancelImageRequestOperation];
	self.image = WLThumbnailFromUrl(imageUrl, self.height);
	if (completion) {
		completion(self.image, YES);
	}
}

- (void)setImage:(UIImage *)image animated:(BOOL)animated {
	[self setImage:image animated:animated duration:0.3];
}

- (void)setImage:(UIImage *)image animated:(BOOL)animated duration:(CGFloat)duration {
	if (animated) {
		CATransition* fadeTransition = [CATransition animation];
		fadeTransition.duration = duration;
		fadeTransition.type = kCATransitionFade;
		[self.layer addAnimation:fadeTransition forKey:nil];
	}
	self.image = image;
}

@end
