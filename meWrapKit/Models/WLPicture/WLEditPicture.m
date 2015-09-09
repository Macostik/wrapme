//
//  WLEditPicture.m
//  meWrap
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEditPicture.h"
#import "WLImageCache.h"
#import "UIImage+Resize.h"
#import "ALAssetsLibrary+Additions.h"
#import "WLImageFetcher.h"
#import "UIImage+Drawing.h"
#import "WLAPIRequest.h"
#import "GCDHelper.h"

@interface WLEditPicture () <WLImageFetching>

@property (nonatomic) BOOL fetching;

@end

@implementation WLEditPicture

- (void)dealloc {
    if (!self.uploaded) {
        [[NSFileManager defaultManager] removeItemAtPath:self.original error:NULL];
        if (![self.original isEqualToString:self.large]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.large error:NULL];
        }
        [[NSFileManager defaultManager] removeItemAtPath:self.medium error:NULL];
        [[NSFileManager defaultManager] removeItemAtPath:self.small error:NULL];
    }
}

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
    WLEditPicture* picture = [self picture:mode cache:cache];
    [picture setImage:image completion:completion];
    return picture;
}

+ (instancetype)picture:(WLStillPictureMode)mode {
    return [self picture:mode cache:[WLImageCache uploadingCache]];
}

+ (instancetype)picture:(WLStillPictureMode)mode cache:(WLImageCache*)cache {
    WLEditPicture* picture = [[self alloc] init];
    picture.mode = mode;
    picture.cache = cache;
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
    CGFloat smallSize = isPad ? (isCandy ? 480 : 160) : (isCandy ? 240 : 160);
    
    __weak WLImageCache *imageCache = cache;
    __weak typeof(self)weakSelf = self;
    [imageCache setImage:image completion:^(NSString *identifier) {
        NSString *largePath = [imageCache pathWithIdentifier:identifier];
        if (weakSelf) {
            weakSelf.large = weakSelf.original = largePath;
            run_getting_object(^id{
                return [image thumbnailImage:smallSize];
            }, ^(UIImage *smallImage) {
                [imageCache setImage:smallImage completion:^(NSString *identifier) {
                    NSString *smallPath = [imageCache pathWithIdentifier:identifier];
                    if (weakSelf) {
                        weakSelf.small = smallPath;
                        if (completion) completion(weakSelf);
                    } else {
                        [[NSFileManager defaultManager] removeItemAtPath:largePath error:NULL];
                        [[NSFileManager defaultManager] removeItemAtPath:smallPath error:NULL];
                        if (completion) completion(weakSelf);
                    }
                }];
            });
        } else {
            [[NSFileManager defaultManager] removeItemAtPath:largePath error:NULL];
            if (completion) completion(weakSelf);
        }
    }];
}

- (void)setOriginal:(NSString *)original {
    if (self.original) {
        [[NSFileManager defaultManager] removeItemAtPath:self.original error:NULL];
    }
    [super setOriginal:original];
}

- (void)setSmall:(NSString *)small {
    if (self.small) {
        [[NSFileManager defaultManager] removeItemAtPath:self.small error:NULL];
    }
    [super setSmall:small];
}

- (WLPicture *)uploadablePicture:(BOOL)justUploaded {
    self.uploaded = YES;
    WLPicture *picture = [[WLPicture alloc] init];
    picture.original = self.original;
    picture.large = self.large;
    picture.medium = self.medium;
    picture.small = self.small;
    picture.justUploaded = justUploaded;
    return picture;
}

- (void)saveToAssets {
    if (!self.fetching) {
        self.fetching = YES;
        [[WLImageFetcher fetcher] enqueueImageWithUrl:self.original receiver:self];
    }
}

- (void)saveToAssetsIfNeeded {
    if (self.saveToAlbum && self.assetID == nil) {
        [self saveToAssets];
    }
}

- (NSDate *)date {
    if (!_date) {
        _date = [NSDate now];
    }
    return _date;
}

// MARK: - WLImageFetching

- (void)fetcher:(WLImageFetcher *)fetcher didFinishWithImage:(UIImage *)image cached:(BOOL)cached {
    [image save:nil];
    self.fetching = NO;
}

- (void)fetcher:(WLImageFetcher *)fetcher didFailWithError:(NSError *)error {
    self.fetching = NO;
}

- (NSString *)fetcherTargetUrl:(WLImageFetcher *)fetcher {
    return self.fetching ? self.original : nil;
}

@end
