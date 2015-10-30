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
#import "WLImageFetcher.h"
#import "WLAPIRequest.h"
#import "GCDHelper.h"
#import "PHPhotoLibrary+Helper.h"

@implementation WLEditPicture

- (instancetype)init {
    self = [super init];
    if (self) {
        self.type = WLCandyTypeImage;
    }
    return self;
}

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

- (void)setVideoAtPath:(NSString*)path completion:(WLObjectBlock)completion {
    if (!completion) {
        return;
    }
    
    WLImageCache *cache = self.cache;
    if (!cache) {
        cache = [WLImageCache cache];
    }
    
    __weak WLImageCache *imageCache = cache;
    __weak typeof(self)weakSelf = self;
    self.original = path;
    run_getting_object(^id{
        
        AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
        
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        imageGenerator.appliesPreferredTrackTransform = YES;
        Float64 duration = CMTimeGetSeconds(asset.duration);
        CMTime time = CMTimeMakeWithSeconds(duration/2.0f, NSEC_PER_SEC);
        NSError *error = nil;
        CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        return image;
    }, ^(UIImage *image) {
        [imageCache setImage:image completion:^(NSString *identifier) {
            NSString *largePath = [imageCache pathWithIdentifier:identifier];
            if (weakSelf) {
                weakSelf.large = largePath;
                run_getting_object(^id{
                    return [image thumbnailImage:240];
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
        
    });
}

- (void)setVideoFromRecordAtPath:(NSString*)path completion:(WLObjectBlock)completion {
    __weak typeof(self)weakSelf = self;
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    NSString *outputPath = [NSString stringWithFormat:@"%@/Documents/%@.mp4", NSHomeDirectory(), GUID()];
    session.outputFileType = AVFileTypeMPEG4;
    session.outputURL = [NSURL fileURLWithPath:outputPath];
    self.videoExportSession = session;
    [session exportAsynchronouslyWithCompletionHandler:^{
        weakSelf.videoExportSession = nil;
        if (session.error) {
            if (completion) completion(weakSelf);
        } else {
            [weakSelf setVideoAtPath:outputPath completion:completion];
        }
    }];
}

- (void)setVideoFromAsset:(PHAsset*)asset completion:(WLObjectBlock)completion {
    __weak typeof(self)weakSelf = self;
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.networkAccessAllowed = YES;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
    [[PHImageManager defaultManager] requestExportSessionForVideo:asset options:options exportPreset:AVAssetExportPresetMediumQuality resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
        weakSelf.videoExportSession = exportSession;
        NSString *path = [NSString stringWithFormat:@"%@/Documents/%@.mp4", NSHomeDirectory(), GUID()];
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.outputURL = [NSURL fileURLWithPath:path];
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            weakSelf.videoExportSession = nil;
            run_in_main_queue(^{
                if (exportSession.error == nil && weakSelf) {
                    [weakSelf setVideoAtPath:path completion:^(id object) {
                        if (completion) completion(weakSelf);
                    }];
                } else {
                    if (completion) completion(weakSelf);
                }
            });
        }];
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

- (WLAsset *)uploadablePicture:(BOOL)justUploaded {
    self.uploaded = YES;
    WLAsset *picture = [[WLAsset alloc] init];
    picture.type = self.type;
    picture.original = self.original;
    picture.large = self.large;
    picture.medium = self.medium;
    picture.small = self.small;
    picture.justUploaded = justUploaded;
    return picture;
}

- (void)saveToAssets {
    [PHPhotoLibrary addAsset:^PHAssetChangeRequest *{
        if (self.type == WLCandyTypeVideo) {
            return [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:self.original]];
        } else {
            return [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL fileURLWithPath:self.original]];
        }
    } collectionTitle:WLAlbumName success:^{
    } failure:^(NSError *error) {
    }];
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

@end
