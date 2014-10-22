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
#import "NSString+Additions.h"

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

- (BOOL)edit:(NSString *)large medium:(NSString *)medium small:(NSString *)small {
    BOOL changed = NO;
    if (!NSStringEqual(self.large, large)) {
        changed = YES;
        self.large = large;
    }
    if (!NSStringEqual(self.medium, medium)) {
        changed = YES;
        self.medium = medium;
    }
    if (!NSStringEqual(self.small, small)) {
        changed = YES;
        self.small = small;
    }
    return changed;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:\nlarge: %@\nmedium: %@\nsmall: %@",[self class],self.large, self.medium, self.small];
}

@end

@implementation WLPicture (JSONValue)

+ (instancetype)pictureWithJSONValue:(NSData *)value {
    WLPicture* picture = [[self alloc] init];
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:value options:0 error:NULL];
    picture.large = data[@"large"];
    picture.medium = data[@"medium"];
    picture.small = data[@"small"];
    return picture;
}

- (NSData*)JSONValue {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data trySetObject:self.large forKey:@"large"];
    [data trySetObject:self.medium forKey:@"medium"];
    [data trySetObject:self.small forKey:@"small"];
    return [NSJSONSerialization dataWithJSONObject:data options:0 error:NULL];
}

@end
