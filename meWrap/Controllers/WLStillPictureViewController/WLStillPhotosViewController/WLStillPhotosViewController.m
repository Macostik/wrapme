//
//  WLStillPhotosViewController.m
//  meWrap
//
//  Created by Ravenpod on 6/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStillPhotosViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLHintView.h"
#import "WLWrapView.h"
#import "WLToast.h"
#import "WLNavigationHelper.h"
#import "WLBatchEditPictureViewController.h"
#import "WLCollections.h"
#import "WLEditPicture.h"

@import Photos;

@interface WLStillPhotosViewController () <WLCameraViewControllerDelegate, UINavigationControllerDelegate, WLEntryNotifyReceiver, WLBatchEditPictureViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray* pictures;

@end

@implementation WLStillPhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pictures = [NSMutableArray array];
    [self performSelector:@selector(updatePicturesCountLabel) withObject:nil afterDelay:0.0f];
}

- (void)handleImage:(UIImage *)image saveToAlbum:(BOOL)saveToAlbum {
    __weak typeof(self)weakSelf = self;
    self.view.userInteractionEnabled = NO;
    WLEditPicture *picture = [WLEditPicture picture:self.mode];
    runQueuedOperation(@"wl_still_picture_queue",1,^(WLOperation *operation) {
        [picture setImage:image completion:^(id object) {
            weakSelf.view.userInteractionEnabled = YES;
            [operation finish];
        }];
    });
    picture.saveToAlbum = saveToAlbum;
    picture.date = [NSDate now];
    [self addPicture:picture success:^{
    } failure:^(NSError *error) {
        [error show];
    }];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewControllerDidFinish:(WLCameraViewController *)controller {
    WLOperationQueue *queue = [WLOperationQueue queueNamed:@"wl_still_picture_queue" capacity:1];
    
    __weak typeof(self)weakSelf = self;
    WLBlock completionBlock = ^ {
        queue.finishQueueBlock = nil;
        
        [weakSelf.pictures sortUsingComparator:^NSComparisonResult(WLEditPicture* obj1, WLEditPicture* obj2) {
            return [obj1.date compare:obj2.date];
        }];
        
        WLBatchEditPictureViewController *editController = [WLBatchEditPictureViewController instantiate:self.storyboard];
        editController.pictures = weakSelf.pictures;
        editController.delegate = weakSelf;
        editController.wrap = weakSelf.wrap;
        [weakSelf pushViewController:editController animated:NO];
    };
    
    if (queue.operations.count == 0) {
        completionBlock();
    } else {
        controller.finishButton.loading = YES;
        [queue setFinishQueueBlock:^{
            controller.finishButton.loading = NO;
            completionBlock();
        }];
    }
}

- (BOOL)cameraViewControllerCaptureMedia:(WLCameraViewController *)controller {
    return [self shouldAddPicture:^{
    } failure:^(NSError *error) {
        [error show];
    }];
}

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithVideoAtPath:(NSString *)path saveToAlbum:(BOOL)saveToAlbum {
    [self handleVideoAtPath:path saveToAlbum:saveToAlbum];
}

- (void)handleVideoAtPath:(NSString*)path saveToAlbum:(BOOL)saveToAlbum {
    WLEditPicture *picture = [WLEditPicture picture:self.mode];
    picture.type = WLCandyTypeVideo;
    picture.date = [NSDate now];
    picture.saveToAlbum = saveToAlbum;
    
    runQueuedOperation(@"wl_still_picture_queue",1,^(WLOperation *operation) {
        [picture setVideoAtPath:path completion:^(id object) {
            [operation finish];
        }];
    });
    
    [self addPicture:picture success:^{
    } failure:^(NSError *error) {
        [error show];
    }];
}

#pragma mark - WLQuickAssetsViewControllerDelegate

- (BOOL)quickAssetsViewController:(WLQuickAssetsViewController *)controller shouldSelectAsset:(PHAsset *)asset {
    if (asset.mediaType == PHAssetMediaTypeVideo && asset.duration >= 61) {
        [WLError(WLLS(@"upload_video_duration_limit_error")) show];
        return NO;
    } else {
        return [self shouldAddPicture:^{
        } failure:^(NSError *error) {
            [error show];
        }];
    }
}

- (void)quickAssetsViewController:(WLQuickAssetsViewController *)controller didSelectAsset:(PHAsset *)asset {
    [self handleAsset:asset];
}

- (void)quickAssetsViewController:(WLQuickAssetsViewController *)controller didDeselectAsset:(PHAsset *)asset {
    [self.pictures removeSelectively:^BOOL(WLEditPicture* picture) {
        if ([picture.assetID isEqualToString:asset.localIdentifier]) {
            if (picture.videoExportSession) {
                [picture.videoExportSession cancelExport];
            }
            return YES;
        }
        return NO;
    }];
    [self updatePicturesCountLabel];
}

- (BOOL)quickAssetsViewControllerShouldPreselectFirstAsset:(WLQuickAssetsViewController *)controller {
    return self.startFromGallery;
}

- (void)handleAsset:(PHAsset*)asset {
    __weak typeof(self)weakSelf = self;
    __weak WLEditPicture *picture = [WLEditPicture picture:self.mode];
    picture.assetID = asset.localIdentifier;
    picture.date = asset.creationDate;
    picture.type = asset.mediaType == PHAssetMediaTypeVideo ? WLCandyTypeVideo : WLCandyTypeImage;
    [self addPicture:picture success:^{
        runQueuedOperation(@"wl_still_picture_queue",1,^(WLOperation *operation) {
            if (asset.mediaType == PHAssetMediaTypeVideo) {
                PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
                options.version = PHVideoRequestOptionsVersionOriginal;
                options.networkAccessAllowed = YES;
                options.deliveryMode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
                [[PHImageManager defaultManager] requestExportSessionForVideo:asset options:options exportPreset:AVAssetExportPresetMediumQuality resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
                    picture.videoExportSession = exportSession;
                    NSString *path = [NSString stringWithFormat:@"%@/Documents/%@.mp4", NSHomeDirectory(), GUID()];
                    exportSession.outputFileType = @"public.mpeg-4";
                    exportSession.outputURL = [NSURL fileURLWithPath:path];
                    [exportSession exportAsynchronouslyWithCompletionHandler:^{
                        picture.videoExportSession = nil;
                        run_in_main_queue(^{
                            if (exportSession.error == nil && picture) {
                                [picture setVideoAtPath:path completion:^(id object) {
                                    [operation finish];
                                }];
                            } else {
                                [operation finish];
                            }
                        });
                    }];
                }];
            } else {
                [weakSelf cropAsset:asset completion:^(UIImage *croppedImage) {
                    [picture setImage:croppedImage completion:^(id object) {
                        [operation finish];
                    }];
                }];
            }
        });
    } failure:^(NSError *error) {
        [error show];
    }];
}

- (void)handleAssets:(NSArray*)assets {
    for (PHAsset* asset in assets) {
        [self handleAsset:asset];
    }
}

- (void)addPicture:(WLEditPicture*)picture success:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [self shouldAddPicture:^{
        [weakSelf.pictures addObject:picture];
        [weakSelf updatePicturesCountLabel];
        if (success) success();
    } failure:failure];
}

- (BOOL)shouldAddPicture:(WLBlock)success failure:(WLFailureBlock)failure {
    if (self.pictures.count < 10) {
        if (success) success();
        return YES;
    } else {
        if (failure) failure(WLError(WLLS(@"upload_photos_limit_error")));
        return NO;
    }
}

- (void)updatePicturesCountLabel {
    [self.cameraViewController.takePhotoButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)self.pictures.count] forState:UIControlStateNormal];
    self.cameraViewController.finishButton.active = self.pictures.count > 0;
}

#pragma mark - WLBatchEditPictureViewControllerDelegate

- (void)batchEditPictureViewController:(WLBatchEditPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    
    for (WLEditPicture *picture in pictures) {
        [picture saveToAssetsIfNeeded];
    }
    
    [self finishWithPictures:pictures];
}

@end
