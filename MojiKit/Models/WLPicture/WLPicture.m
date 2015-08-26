//
//  WLPicture.m
//  moji
//
//  Created by Ravenpod on 28.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPicture.h"
#import "WLImageCache.h"
#import "UIImage+Resize.h"
#import "NSString+Additions.h"
#import "NSDictionary+Extended.h"
#import "WLBlockImageFetching.h"
#import "WLImageFetcher.h"
#import "WLEntryKeys.h"
#import "WLAPIEnvironment.h"

@implementation WLPicture

- (NSString *)anyUrl {
    return self.small ? : (self.medium ? : self.large);
}

- (WLPicture *)edit:(NSString *)original large:(NSString *)large medium:(NSString *)medium small:(NSString *)small {
    
    WLPicture *picture = self;
    if (original.nonempty && !NSStringEqual(self.original, original)) {
        if (picture == self) picture = [self copy];
        picture.original = original;
    }
    if (large.nonempty && !NSStringEqual(self.large, large)) {
        if (picture == self) picture = [self copy];
        picture.large = large;
    }
    if (medium.nonempty && !NSStringEqual(self.medium, medium)) {
        if (picture == self) picture = [self copy];
        picture.medium = medium;
    }
    if (small.nonempty && !NSStringEqual(self.small, small)) {
        if (picture == self) picture = [self copy];
        picture.small = small;
    }
    return picture;
}

- (WLPicture *)editWithCandyDictionary:(NSDictionary *)dictionary {
    NSString *original = nil;
    NSString *large = nil;
    NSString *medium = nil;
    NSString *small = nil;
    
    if (dictionary[WLCandyURLsKey]) {
        NSDictionary *urls = dictionary[WLCandyURLsKey];
        original = [self prependUrl:[urls stringForKey:WLURLOriginalKey] withUri:WLImageURI];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            large = [self prependUrl:[urls stringForKey:WLURLXLargeKey] withUri:WLImageURI];
            medium = [self prependUrl:[urls stringForKey:WLURLLargeSQKey] withUri:WLImageURI];
            small = [self prependUrl:[urls stringForKey:WLURLMediumSQKey] withUri:WLImageURI];
        } else {
            large = [self prependUrl:[urls stringForKey:WLURLLargeKey] withUri:WLImageURI];
            medium = [self prependUrl:[urls stringForKey:WLURLMediumSQKey] withUri:WLImageURI];
            small = [self prependUrl:[urls stringForKey:WLURLSmallSQKey] withUri:WLImageURI];
        }
    } else {
        original = [dictionary stringForKey:WLCandyOriginalURLKey];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            large = [dictionary stringForKey:WLCandyXLargeURLKey];
            medium = [dictionary stringForKey:WLCandyXMediumURLKey];
            small = [dictionary stringForKey:WLCandyXSmallURLKey];
        } else {
            large = [dictionary stringForKey:WLCandyLargeURLKey];
            medium = [dictionary stringForKey:WLCandyMediumURLKey];
            small = [dictionary stringForKey:WLCandySmallURLKey];
        }
    }
    
    return [self edit:original large:large medium:medium small:small];
}

- (NSString*)prependUrl:(NSString*)url withUri:(NSString*)uri {
    return url.nonempty ? [uri stringByAppendingString:url] : nil;
}

- (WLPicture *)editWithUserDictionary:(NSDictionary *)dictionary {
    NSString *original = nil;
    NSString *large = nil;
    NSString *medium = nil;
    NSString *small = nil;
    if (dictionary[WLAvatarURLsKey]) {
        NSDictionary *urls = dictionary[WLAvatarURLsKey];
        large = [self prependUrl:[urls stringForKey:WLURLLargeKey] withUri:WLAvatarURI];
        medium = [self prependUrl:[urls stringForKey:WLURLMediumKey] withUri:WLAvatarURI];
        small = [self prependUrl:[urls stringForKey:WLURLSmallKey] withUri:WLAvatarURI];
    } else {
        large = [dictionary stringForKey:WLLargeAvatarKey];
        medium = [dictionary stringForKey:WLMediumAvatarKey];
        small = [dictionary stringForKey:WLSmallAvatarKey];
    }
    
    original = large;
    
    return [self edit:original large:large medium:medium small:small];
}

- (WLPicture *)editWithContributorDictionary:(NSDictionary *)dictionary {
    NSString *original = nil;
    NSString *large = nil;
    NSString *medium = nil;
    NSString *small = nil;
    if (dictionary[WLAvatarURLsKey]) {
        NSDictionary *urls = dictionary[WLAvatarURLsKey];
        large = [self prependUrl:[urls stringForKey:WLURLLargeKey] withUri:WLAvatarURI];
        medium = [self prependUrl:[urls stringForKey:WLURLMediumKey] withUri:WLAvatarURI];
        small = [self prependUrl:[urls stringForKey:WLURLSmallKey] withUri:WLAvatarURI];
    } else {
        large = [dictionary stringForKey:WLContributorLargeAvatarKey];
        medium = [dictionary stringForKey:WLContributorMediumAvatarKey];
        small = [dictionary stringForKey:WLContributorSmallAvatarKey];
    }
    
    original = large;
    
    return [self edit:original large:large medium:medium small:small];
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

- (void)cacheForPicture:(WLPicture *)picture {
    WLImageCache *cache = [WLImageCache cache];
    [cache setImageAtPath:self.original withUrl:picture.original];
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
    picture.justUploaded = self.justUploaded;
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
