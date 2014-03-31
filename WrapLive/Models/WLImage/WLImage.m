//
//  WLImage.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLImage.h"

@implementation WLImage

+ (instancetype)entry {
	WLImage *image = [super entry];
	image.type = WLCandyTypeImage;
	return image;
}

- (NSString *)cover {
	NSString* cover = [super cover];
	if (cover.length > 0) {
		return cover;
	}
	return self.url;
}

@end
