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
#import "WLToast.h"
#import "WLBatchEditPictureViewController.h"

@import Photos;

@interface WLStillPhotosViewController () <WLCameraViewControllerDelegate, UINavigationControllerDelegate, WLBatchEditPictureViewControllerDelegate>

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
    MutableAsset *picture = [[MutableAsset alloc] init];
    picture.mode = self.mode;
    picture.canBeSavedToAssets = saveToAlbum;
    [self addPicture:picture success:^(MutableAsset *picture){
        runQueuedOperation(@"wl_still_picture_queue",1,^(WLOperation *operation) {
            [picture setImage:image completion:^(id object) {
                weakSelf.view.userInteractionEnabled = YES;
                [operation finish];
            }];
        });
    } failure:^(NSError *error) {
        [error show];
    }];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewControllerDidFinish:(WLCameraViewController *)controller {
    WLOperationQueue *queue = [WLOperationQueue queueNamed:@"wl_still_picture_queue" capacity:1];
    
    __weak typeof(self)weakSelf = self;
    Block completionBlock = ^ {
        queue.finishQueueBlock = nil;
        
        [weakSelf.pictures sortUsingComparator:^NSComparisonResult(MutableAsset *obj1, MutableAsset *obj2) {
            return [obj1.date compare:obj2.date];
        }];
        
        WLBatchEditPictureViewController *editController = self.storyboard[@"WLBatchEditPictureViewController"];
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
    MutableAsset *picture = [[MutableAsset alloc] init];
    picture.mode = self.mode;
    picture.type = MediaTypeVideo;
    picture.date = [NSDate now];
    picture.canBeSavedToAssets = saveToAlbum;
    [self addPicture:picture success:^(MutableAsset *picture) {
        controller.takePhotoButton.userInteractionEnabled = NO;
        runQueuedOperation(@"wl_still_picture_queue",1,^(WLOperation *operation) {
            [picture setVideoFromRecordAtPath:path completion:^(id object) {
                [operation finish];
                controller.takePhotoButton.userInteractionEnabled = YES;
            }];
        });
    } failure:^(NSError *error) {
        [error show];
    }];
}

#pragma mark - AssetsViewControllerDelegate

- (BOOL)assetsViewController:(AssetsViewController *)controller shouldSelectAsset:(PHAsset *)asset {
    if (asset.mediaType == PHAssetMediaTypeVideo && asset.duration >= [Constants maxVideoRecordedDuration] + 1) {
        [[[NSError alloc] initWithMessage:[NSString stringWithFormat:@"formatted_upload_video_duration_limit".ls, (int)[Constants maxVideoRecordedDuration]]] show];
        return NO;
    } else {
        return [self shouldAddPicture:^{
        } failure:^(NSError *error) {
            [error show];
        }];
    }
}

- (void)assetsViewController:(AssetsViewController *)controller didSelectAsset:(PHAsset *)asset {
    [self handleAsset:asset];
}

- (void)assetsViewController:(AssetsViewController *)controller didDeselectAsset:(PHAsset *)asset {
    [self.pictures removeSelectively:^BOOL(MutableAsset *picture) {
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

- (BOOL)assetsViewControllerShouldPreselectFirstAsset:(AssetsViewController *)controller {
    return self.startFromGallery;
}

- (void)handleAsset:(PHAsset*)asset {
    __weak typeof(self)weakSelf = self;
    MutableAsset *picture = [[MutableAsset alloc] init];
    picture.mode = self.mode;
    picture.assetID = asset.localIdentifier;
    picture.date = asset.creationDate;
    picture.type = asset.mediaType == PHAssetMediaTypeVideo ? MediaTypeVideo : MediaTypePhoto;
    [self addPicture:picture success:^(MutableAsset *picture) {
        runQueuedOperation(@"wl_still_picture_queue",1,^(WLOperation *operation) {
            if (asset.mediaType == PHAssetMediaTypeVideo) {
                [picture setVideoFromAsset:asset completion:^(id object) {
                    [operation finish];
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

- (void)addPicture:(MutableAsset *)picture success:(ObjectBlock)success failure:(FailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [self shouldAddPicture:^{
        [weakSelf.pictures addObject:picture];
        [weakSelf updatePicturesCountLabel];
        if (success) success(picture);
    } failure:failure];
}

- (BOOL)shouldAddPicture:(Block)success failure:(FailureBlock)failure {
    if (self.pictures.count < 10) {
        if (success) success();
        return YES;
    } else {
        if (failure) failure([[NSError alloc] initWithMessage:@"upload_photos_limit_error".ls]);
        return NO;
    }
}

- (void)updatePicturesCountLabel {
    [self.cameraViewController.takePhotoButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)self.pictures.count] forState:UIControlStateNormal];
    self.cameraViewController.finishButton.hidden = self.pictures.count == 0;
}

#pragma mark - WLBatchEditPictureViewControllerDelegate

- (void)batchEditPictureViewController:(WLBatchEditPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    
    for (MutableAsset *picture in pictures) {
        [picture saveToAssetsIfNeeded];
    }
    
    [self finishWithPictures:pictures];
}

@end
