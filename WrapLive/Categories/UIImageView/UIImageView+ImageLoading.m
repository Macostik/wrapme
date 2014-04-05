//
//  UIImageView+ImageLoading.m
//  WrapLive
//
//  Created by Sergey Maximenko on 31.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIImageView+ImageLoading.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@implementation UIImageView (ImageLoading)

@dynamic imageUrl;

- (void)setImageUrl:(NSString *)imageUrl {
	[self setImageUrl:imageUrl completion:nil];
}

- (void)setImageUrl:(NSString *)imageUrl completion:(void (^)(UIImage* image, BOOL cached))completion {
	NSURL* url = [NSURL URLWithString:imageUrl];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
	__weak typeof(self)weakSelf = self;
	[self setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
		if (request != nil) {
			CATransition* fadeTransition = [CATransition animation];
			fadeTransition.duration = 0.3;
			fadeTransition.type = kCATransitionFade;
			[weakSelf.layer addAnimation:fadeTransition forKey:nil];
		}
		weakSelf.image = image;
		if (completion) {
			completion(image, request == nil);
		}
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
		if (completion) {
			completion(nil, NO);
		}
	}];
}

@end
