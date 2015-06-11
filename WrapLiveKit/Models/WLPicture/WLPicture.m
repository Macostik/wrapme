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

- (NSString *)anyUrl {
    return self.small ? : (self.medium ? : self.large);
}

- (WLPicture *)edit:(NSString *)original large:(NSString *)large medium:(NSString *)medium small:(NSString *)small {
    
    WLPicture *(^changeBlock)(void) = ^WLPicture *{
        WLPicture *picture = [self copy];
        picture.small = small;
        picture.original = original;
        picture.medium = medium;
        picture.large = large;
        return picture;
    };
    
    if (original.nonempty && !NSStringEqual(self.original, original)) {
        return changeBlock();
    }
    if (large.nonempty && !NSStringEqual(self.large, large)) {
        return changeBlock();
    }
    if (medium.nonempty && !NSStringEqual(self.medium, medium)) {
        return changeBlock();
    }
    if (small.nonempty && !NSStringEqual(self.small, small)) {
        return changeBlock();
    }
    return self;
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

- (void)setAnimation:(WLAnimation *)animation {
    _animation = animation;
    __weak typeof(self)weakSelf = self;
    [animation setCompletionBlock:^{
        weakSelf.animation = nil;
    }];
}

- (void)cacheForPicture:(WLPicture *)picture {
    WLImageCache *cache = [WLImageCache cache];
    [cache setImageAtPath:self.original withUrl:picture.original];
    [cache setImageAtPath:self.medium withUrl:picture.medium];
    [cache setImageAtPath:self.small withUrl:picture.small];
    [cache setImageAtPath:self.large withUrl:picture.large];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:\noriginal: %@\nlarge: %@\nmedium: %@\nsmall: %@",[self class],self.original,self.large, self.medium, self.small];
}

- (id)copyWithZone:(NSZone *)zone {
    WLPicture *picture = [[[self class] allocWithZone:zone] init];
    picture.original = self.original;
    picture.small = self.small;
    picture.medium = self.medium;
    picture.large = self.large;
    picture.animation = self.animation;
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
