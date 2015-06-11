//
//  WLEditPicture.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEditPicture.h"
#import "WLImageCache.h"
#import "UIImage+Resize.h"

@implementation WLEditPicture

+ (instancetype)picture:(UIImage *)image completion:(WLObjectBlock)completion {
    return [self picture:image cache:[WLImageCache uploadingCache] completion:completion];
}

+ (instancetype)picture:(UIImage *)image cache:(WLImageCache *)cache completion:(WLObjectBlock)completion {
    return [self picture:image mode:WLStillPictureModeDefault cache:cache completion:completion];
}

+ (instancetype)picture:(UIImage *)image mode:(WLStillPictureMode)mode completion:(WLObjectBlock)completion {
    return [self picture:image mode:mode cache:[WLImageCache uploadingCache] completion:completion];
}

+ (instancetype)picture:(UIImage *)image mode:(WLStillPictureMode)mode cache:(WLImageCache *)cache completion:(WLObjectBlock)completion {
    WLEditPicture* picture = [[self alloc] init];
    picture.mode = mode;
    picture.cache = cache;
    [picture setImage:image completion:completion];
    return picture;
}

- (void)setImage:(UIImage *)image completion:(WLObjectBlock)completion {
    if (!completion) {
        return;
    }
    
    WLImageCache *cache = self.cache;
    if (!cache) {
        cache = [WLImageCache cache];
    }
    
    BOOL isPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    BOOL isCandy = self.mode == WLStillPictureModeDefault;
    
    __weak WLImageCache *imageCache = cache;
    __weak typeof(self)weakSelf = self;
    run_in_default_queue(^{
        __block NSData *metadataImage = UIImageJPEGRepresentation(image, .5f);
        [imageCache setImageData:metadataImage completion:^(NSString *path) {
            weakSelf.original = weakSelf.large = [imageCache pathWithIdentifier:path];
            CGFloat size = isPad ? (isCandy ? 720 : 320) : (isCandy ? 480 : 320);
            metadataImage =  UIImageJPEGRepresentation([image thumbnailImage:size], 1.0f);
            [imageCache setImageData:metadataImage completion:^(NSString *path) {
                weakSelf.medium = [imageCache pathWithIdentifier:path];
                CGFloat size = isPad ? (isCandy ? 480 : 160) : (isCandy ? 240 : 160);
                metadataImage = UIImageJPEGRepresentation([image thumbnailImage:size], 1.0f);
                [imageCache setImageData:metadataImage completion:^(NSString *path) {
                    weakSelf.small = [imageCache pathWithIdentifier:path];
                    run_in_main_queue(^ {
                        if (completion) completion(weakSelf);
                    });
                }];
            }];
        }];
    });
}

- (WLPicture *)uploadablePictureWithAnimation:(BOOL)withAnimation {
    WLPicture *picture = [[WLPicture alloc] init];
    picture.original = self.original;
    picture.large = self.large;
    picture.medium = self.medium;
    picture.small = self.small;
    if (withAnimation) {
        picture.animation = [WLAnimation animationWithDuration:0.5f];
    }
    return picture;
}

@end
