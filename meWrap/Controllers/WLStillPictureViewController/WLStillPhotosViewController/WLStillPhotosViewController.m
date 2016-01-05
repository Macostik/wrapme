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
#import "WLBatchEditPictureViewController.h"

@import Photos;

@interface WLStillPhotosViewController () <WLCameraViewControllerDelegate, UINavigationControllerDelegate, WLBatchEditPictureViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray* pictures;

@property (strong, nonatomic) RunQueue *runQueue;

@property (weak, nonatomic) AssetsViewController *assetsViewController;

@end

@implementation WLStillPhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.runQueue = [[RunQueue alloc] initWithLimit:3];
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
        [weakSelf.runQueue run:^(Block finish) {
            [picture setImage:image completion:^(id object) {
                weakSelf.view.userInteractionEnabled = YES;
                finish();
            }];
        }];
    } failure:^(NSError *error) {
        [error show];
    }];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewControllerDidFinish:(WLCameraViewController *)controller {
    RunQueue *queue = self.runQueue;
    
    __weak typeof(self)weakSelf = self;
    Block completionBlock = ^ {
        queue.didFinish = nil;
        
        [weakSelf.pictures sortUsingComparator:^NSComparisonResult(MutableAsset *obj1, MutableAsset *obj2) {
            return [obj1.date compare:obj2.date];
        }];
        
        WLBatchEditPictureViewController *editController = (id)self.storyboard[@"WLBatchEditPictureViewController"];
        editController.assets = weakSelf.pictures;
        editController.delegate = weakSelf;
        editController.wrap = weakSelf.wrap;
        [weakSelf pushViewController:editController animated:NO];
    };
    
    if (queue.isExecuting) {
        controller.finishButton.loading = YES;
        [queue setDidFinish:^{
            controller.finishButton.loading = NO;
            completionBlock();
        }];
    } else {
        completionBlock();
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
    __weak typeof(self)weakSelf = self;
    [self addPicture:picture success:^(MutableAsset *picture) {
        controller.takePhotoButton.userInteractionEnabled = NO;
        [weakSelf.runQueue run:^(Block finish) {
            [picture setVideoFromRecordAtPath:path completion:^(id object) {
                finish();
                controller.takePhotoButton.userInteractionEnabled = YES;
            }];
        }];
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
    self.assetsViewController = controller;
    [self handleAsset:asset];
}

- (void)assetsViewController:(AssetsViewController *)controller didDeselectAsset:(PHAsset *)asset {
    for (MutableAsset *_asset in self.pictures) {
        if ([_asset.assetID isEqualToString:asset.localIdentifier]) {
            if (_asset.videoExportSession) {
                [_asset.videoExportSession cancelExport];
            }
            [self.pictures removeObject:_asset];
            break;
        }
    }
    [self updatePicturesCountLabel];
}

- (void)handleAsset:(PHAsset*)asset {
    __weak typeof(self)weakSelf = self;
    MutableAsset *picture = [[MutableAsset alloc] init];
    picture.mode = self.mode;
    picture.assetID = asset.localIdentifier;
    picture.date = asset.creationDate;
    picture.type = asset.mediaType == PHAssetMediaTypeVideo ? MediaTypeVideo : MediaTypePhoto;
    
    [self addPicture:picture success:^(MutableAsset *picture) {
        [weakSelf.runQueue run:^(Block finish) {
            if (asset.mediaType == PHAssetMediaTypeVideo) {
                [picture setVideoFromAsset:asset completion:^(id object) {
                    finish();
                }];
            } else {
                [weakSelf cropAsset:asset completion:^(UIImage *croppedImage) {
                    [picture setImage:croppedImage completion:^(id object) {
                        finish();
                    }];
                }];
            }
        }];
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

- (void)batchEditPictureViewController:(WLBatchEditPictureViewController *)controller didFinishWithAssets:(NSArray *)assets {
    
    for (MutableAsset *asset in assets) {
        [asset saveToAssetsIfNeeded];
    }
    
    [self finishWithPictures:assets];
}

- (void)batchEditPictureViewController:(WLBatchEditPictureViewController *)controller didDeselectAsset:(MutableAsset *)asset {
    [self.pictures removeObject:asset];
    
    NSMutableSet *selectedAssets = [NSMutableSet set];
    for (MutableAsset *_asset in self.pictures) {
        if (_asset.assetID.nonempty) {
            [selectedAssets addObject:_asset.assetID];
        }
    }
  
    self.assetsViewController.selectedAssets = selectedAssets;
    [self.assetsViewController.streamView reload];
    
    
    [self updatePicturesCountLabel];
}

@end
