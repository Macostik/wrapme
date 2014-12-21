//
//  UIImage+Drawing.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "UIImage+Drawing.h"
#import "NSString+Documents.h"
#import "ALAssetsLibrary+Additions.h"
#import "NSMutableDictionary+ImageMetadata.h"

@implementation UIImage (Drawing)

+ (void)drawAssetNamed:(NSString*)name directory:(NSString*)directory size:(CGSize)size opaque:(BOOL)opaque drawing:(void (^)(CGSize))drawing {
    NSArray* scales = @[@1,@2,@3];
    for (NSNumber* scale in scales) {
        UIGraphicsBeginImageContextWithOptions(size, opaque, [scale floatValue]);
        drawing(size);
        NSData *data = UIImagePNGRepresentation(UIGraphicsGetImageFromCurrentImageContext());
        if ([scale floatValue] == 1) {
            [data writeToFile:[directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", name]] atomically:NO];
        } else {
            [data writeToFile:[directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@%@x.png", name, scale]] atomically:NO];
        }
        
        UIGraphicsEndImageContext();
    }
}

+ (void)drawAssetNamed:(NSString *)name directory:(NSString *)directory size:(CGSize)size drawing:(void (^)(CGSize))drawing {
    [self drawAssetNamed:name directory:directory size:size opaque:YES drawing:drawing];
}

- (void)save:(NSMutableDictionary *)metadata {
    [metadata setImageOrientation:self.imageOrientation];
    run_in_default_queue(^{
        ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
        [library saveImage:self
                   toAlbum:WLAlbumName
                  metadata:metadata
                completion:^(NSURL *assetURL, NSError *error) { }
                   failure:^(NSError *error) { }];
    });
}

@end
