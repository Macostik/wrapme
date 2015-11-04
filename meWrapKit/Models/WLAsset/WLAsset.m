//
//  WLAsset.m
//  meWrap
//
//  Created by Ravenpod on 28.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAsset.h"
#import "WLImageCache.h"
#import "NSString+Additions.h"
#import "NSDictionary+Extended.h"
#import "WLBlockImageFetching.h"
#import "WLImageFetcher.h"
#import "WLEntryKeys.h"
#import "WLSession.h"

@implementation WLAsset

+ (NSSet *)archivableProperties {
    return [NSSet setWithObjects:@"type",@"original",@"large",@"medium",@"small", nil];
}

- (NSString *)anyUrl {
    return self.small ? : (self.medium ? : self.large);
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
        __block NSUInteger fetched = 0;
        for (NSString *url in urls) {
            [[WLBlockImageFetching fetchingWithUrl:url] enqueue:^(UIImage *image) {
                fetched++;
                if (urls.count == fetched) {
                    completion();
                }
            } failure:^(NSError *error) {
                fetched++;
                if (urls.count == fetched) {
                    completion();
                }
            }];
        }
    } else {
        completion();
    }
}

- (void)cacheForPicture:(WLAsset *)picture {
    WLImageCache *cache = [WLImageCache cache];
    if (![self.original hasPrefix:@"mp4"]) {
        [cache setImageAtPath:self.original withUrl:picture.original];
    }
    [cache setImageAtPath:self.small withUrl:picture.small];
    [cache setImageAtPath:self.large withUrl:picture.large];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:\noriginal: %@\nlarge: %@\nmedium: %@\nsmall: %@",[self class],self.original,self.large, self.medium, self.small];
}

- (id)copyWithZone:(NSZone *)zone {
    WLAsset *picture = [[[self class] allocWithZone:zone] init];
    picture.original = self.original;
    picture.small = self.small;
    picture.medium = self.medium;
    picture.large = self.large;
    picture.justUploaded = self.justUploaded;
    return picture;
}

@end

@implementation WLAsset (JSONValue)

+ (instancetype)pictureWithJSONValue:(NSData *)value {
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:value options:0 error:NULL];
    if (data) {
        WLAsset* picture = [[self alloc] init];
        picture.original = data[@"original"];
        picture.large = data[@"large"];
        picture.medium = data[@"medium"];
        picture.small = data[@"small"];
        if (data[@"type"]) {
            picture.type = [data integerForKey:@"type"];
        } else {
            picture.type = WLCandyTypeImage;
        }
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
    [data trySetObject:@(self.type > 0 ? self.type : WLCandyTypeImage) forKey:@"type"];
    return [NSJSONSerialization dataWithJSONObject:data options:0 error:NULL];
}

@end

@implementation WLAssetTransformer

+ (Class)transformedValueClass {
    return [NSData class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(WLAsset*)value {
    id transformedValue = [value JSONValue];
    return transformedValue;
}

- (id)reverseTransformedValue:(id)value {
    id reverseTransformedValue = [WLAsset pictureWithJSONValue:value];
    if (!reverseTransformedValue) {
        reverseTransformedValue = [WLAsset unarchive:value];
    }
    return reverseTransformedValue;
}

@end
