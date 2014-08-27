//
//  WLPicture.m
//  WrapLive
//
//  Created by Sergey Maximenko on 28.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLPicture.h"
#import "WLImageCache.h"
#import "UIImage+Resize.h"

@implementation WLPicture

+ (void)picture:(UIImage *)image completion:(WLObjectBlock)completion {
    if (!completion) {
        return;
    }
    __weak WLImageCache *imageCache = [WLImageCache cache];
	[imageCache setImage:image completion:^(NSString *identifier) {
		WLPicture* picture = [[self alloc] init];
        picture.animate = YES;
		picture.large = [imageCache pathWithIdentifier:identifier];
		[imageCache setImage:[image thumbnailImage:320] completion:^(NSString *identifier) {
			picture.medium = [imageCache pathWithIdentifier:identifier];
			[imageCache setImage:[image thumbnailImage:160] completion:^(NSString *identifier) {
				picture.small = [imageCache pathWithIdentifier:identifier];
                completion(picture);
			}];
		}];
	}];
}

- (NSString *)anyUrl {
    return self.small ? : (self.medium ? : self.large);
}

@end
