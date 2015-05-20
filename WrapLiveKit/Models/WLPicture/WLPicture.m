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
#import "NSDictionary+Extended.h"
#import "WLImageFetcher.h"

@implementation WLPicture

+ (void)picture:(UIImage *)image completion:(WLObjectBlock)completion {
    [self picture:image cache:[WLImageCache uploadingCache] completion:completion];
}

+ (void)picture:(UIImage *)image cache:(WLImageCache *)cache completion:(WLObjectBlock)completion {
    [self picture:image mode:WLStillPictureModeDefault cache:cache completion:completion];
}

+ (void)picture:(UIImage *)image mode:(WLStillPictureMode)mode completion:(WLObjectBlock)completion {
    [self picture:image mode:mode cache:[WLImageCache uploadingCache] completion:completion];
}

+ (void)picture:(UIImage *)image mode:(WLStillPictureMode)mode cache:(WLImageCache *)cache completion:(WLObjectBlock)completion {
    if (!completion) {
        return;
    }
    if (!cache) {
        cache = [WLImageCache cache];
    }
    
    BOOL isPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    BOOL isCandy = mode == WLStillPictureModeDefault;
    
    __weak WLImageCache *imageCache = cache;
    run_in_default_queue(^{
        __block NSData *metadataImage = UIImageJPEGRepresentation(image, .5f);
        [imageCache setImageData:metadataImage completion:^(NSString *path) {
            WLPicture* picture = [[self alloc] init];
            picture.original = picture.large = [imageCache pathWithIdentifier:path];
            CGFloat size = isPad ? (isCandy ? 720 : 320) : (isCandy ? 480 : 320);
            metadataImage =  UIImageJPEGRepresentation([image thumbnailImage:size], 1.0f);
            [imageCache setImageData:metadataImage completion:^(NSString *path) {
                picture.medium = [imageCache pathWithIdentifier:path];
                CGFloat size = isPad ? (isCandy ? 480 : 160) : (isCandy ? 240 : 160);
                metadataImage = UIImageJPEGRepresentation([image thumbnailImage:size], 1.0f);
                [imageCache setImageData:metadataImage completion:^(NSString *path) {
                    picture.small = [imageCache pathWithIdentifier:path];
                    run_in_main_queue(^ {
                        if (completion) completion(picture);
                    });
                }];
            }];
        }];
    });
}

- (NSString *)anyUrl {
    return self.small ? : (self.medium ? : self.large);
}

- (BOOL)edit:(NSString *)original large:(NSString *)large medium:(NSString *)medium small:(NSString *)small {
    BOOL changed = NO;
    if (original.nonempty && !NSStringEqual(self.original, original)) {
        changed = YES;
        self.original = original;
    }
    if (large.nonempty && !NSStringEqual(self.large, large)) {
        changed = YES;
        self.large = large;
    }
    if (medium.nonempty && !NSStringEqual(self.medium, medium)) {
        changed = YES;
        self.medium = medium;
    }
    if (small.nonempty && !NSStringEqual(self.small, small)) {
        changed = YES;
        self.small = small;
    }
    return changed;
}

- (NSString *)original {
    if (!_original) {
        _original = self.large;
    }
    return _original;
}

- (void)fetch:(WLBlock)completion {
    if (!completion) {
        [[WLImageFetcher fetcher] enqueueImageWithUrl:self.small];
        [[WLImageFetcher fetcher] enqueueImageWithUrl:self.medium];
        [[WLImageFetcher fetcher] enqueueImageWithUrl:self.large];
        return;
    }
    
    NSMutableSet *urls = [NSMutableSet set];
    
    if (self.small) [urls addObject:self.small];
    if (self.medium) [urls addObject:self.medium];
    if (self.large) [urls addObject:self.large];
    
    if (urls.count > 0) {
        for (NSString *url in urls) {
            run_after_asap(^{
                [[WLImageFetcher fetcher] enqueueImageWithUrl:url completion:^(UIImage *image){
                    [urls removeObject:url];
                    if (urls.count == 0) {
                        if (completion) completion();
                    }
                }];
            });
        }
    } else {
        if (completion) completion();
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:\noriginal: %@\nlarge: %@\nmedium: %@\nsmall: %@",[self class],self.original,self.large, self.medium, self.small];
}

- (id)copyWithZone:(NSZone *)zone {
    WLPicture *picture = [[WLPicture allocWithZone:zone] init];
    picture.original = self.original;
    picture.small = self.small;
    picture.medium = self.medium;
    picture.large = self.large;
    return picture;
}

@end

@implementation WLPicture (JSONValue)

+ (instancetype)pictureWithJSONValue:(NSData *)value {
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:value options:0 error:NULL];
    if (data) {
        WLPicture* picture = [[self alloc] init];
        picture.original = data[@"original"];
        picture.large = data[@"large"];
        picture.medium = data[@"medium"];
        picture.small = data[@"small"];
        return picture;
    }
    return nil;
}

- (NSData*)JSONValue {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data trySetObject:self.original forKey:@"original"];
    [data trySetObject:self.large forKey:@"large"];
    [data trySetObject:self.medium forKey:@"medium"];
    [data trySetObject:self.small forKey:@"small"];
    return [NSJSONSerialization dataWithJSONObject:data options:0 error:NULL];
}

@end

@implementation WLPictureTransformer

+ (Class)transformedValueClass {
    return [NSData class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(WLPicture*)value {
    id transformedValue = [value JSONValue];
    return transformedValue;
}

- (id)reverseTransformedValue:(id)value {
    id reverseTransformedValue = [WLPicture pictureWithJSONValue:value];
    if (!reverseTransformedValue) {
        reverseTransformedValue = [WLPicture unarchive:value];
    }
    return reverseTransformedValue;
}

@end
