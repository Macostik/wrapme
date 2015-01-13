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

@implementation WLPicture

+ (void)picture:(UIImage *)image completion:(WLObjectBlock)completion {
    if (!completion) {
        return;
    }
    __weak WLImageCache *imageCache = [WLImageCache cache];
    run_in_background_queue(^{
        __block NSData *metadataImage = UIImageJPEGRepresentation(image, .5f);
        [imageCache setImageData:metadataImage completion:^(NSString *path) {
            WLPicture* picture = [[self alloc] init];
            picture.large = [imageCache pathWithIdentifier:path];
            metadataImage =  UIImageJPEGRepresentation([image thumbnailImage:320.0f], 1.0f);
            [imageCache setImageData:metadataImage completion:^(NSString *path) {
                picture.medium = [imageCache pathWithIdentifier:path];
                metadataImage = UIImageJPEGRepresentation([image thumbnailImage:160.0f], 1.0f);
                [imageCache setImageData:metadataImage completion:^(NSString *path) {
                    picture.small = [imageCache pathWithIdentifier:path];
                    completion(picture);
                }];
            }];
        }];
    });
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
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:value options:0 error:NULL];
    if (data) {
        WLPicture* picture = [[self alloc] init];
        picture.large = data[@"large"];
        picture.medium = data[@"medium"];
        picture.small = data[@"small"];
        return picture;
    }
    return nil;
}

- (NSData*)JSONValue {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
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
