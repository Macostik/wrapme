//
//  WLImage.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLImage.h"
#import "WLPicture.h"

@implementation WLImage

+ (instancetype)entry {
	WLImage *image = [super entry];
	image.type = WLCandyTypeImage;
	return image;
}

- (WLPicture *)cover {
	return self.url;
}

- (WLPicture *)url {
	if (!_url) {
		_url = [[WLPicture alloc] init];
	}
	return _url;
}

@end
