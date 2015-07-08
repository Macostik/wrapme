//
//  WLNewStillPictureViewController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLNewStillPictureViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLHintView.h"
#import "WLWrapView.h"
#import "WLNavigationAnimator.h"
#import "WLSoundPlayer.h"
#import "WLToast.h"
#import "ALAssetsLibrary+Additions.h"
#import "NSMutableDictionary+ImageMetadata.h"
#import "UIView+AnimationHelper.h"
#import "WLAssetsGroupViewController.h"
#import "WLNavigationHelper.h"
#import "UIButton+Additions.h"
#import "WLBatchEditPictureViewController.h"
#import "NSArray+Additions.h"

@interface WLNewStillPictureViewController () <WLCameraViewControllerDelegate, UINavigationControllerDelegate, WLEntryNotifyReceiver, WLAssetsViewControllerDelegate, WLBatchEditPictureViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray* pictures;

@end

@implementation WLNewStillPictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pictures = [NSMutableArray array];
    [self performSelector:@selector(updatePicturesCountLabel) withObject:nil afterDelay:0.0f];
}

- (void)handleImage:(UIImage *)image metadata:(NSMutableDictionary *)metadata saveToAlbum:(BOOL)saveToAlbum {
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

- (void)cameraViewControllerDidFinish:(WLCameraViewController *)controller sender:(WLButton*)sender {
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
        sender.loading = YES;
        [queue setFinishQueueBlock:^{
            sender.loading = NO;
            completionBlock();
        }];
    }
}

- (BOOL)cameraViewControllerShouldTakePhoto:(WLCameraViewController *)controller {
    return [self shouldAddPicture:^{
    } failure:^(NSError *error) {
        [error show];
    }];
}

#pragma mark - WLQuickAssetsViewControllerDelegate

- (BOOL)quickAssetsViewController:(WLQuickAssetsViewController *)controller shouldSelectAsset:(ALAsset *)asset {
    return [self shouldAddPicture:^{
    } failure:^(NSError *error) {
        [error show];
    }];
}

- (void)quickAssetsViewController:(WLQuickAssetsViewController *)controller didSelectAsset:(ALAsset *)asset {
    [self handleAssets:@[asset]];
}

- (void)quickAssetsViewController:(WLQuickAssetsViewController *)controller didDeselectAsset:(ALAsset *)asset {
    [self.pictures removeObjectsWhileEnumerating:^BOOL(WLEditPicture* picture) {
        return [picture.assetID isEqualToString:asset.ID];
    }];
    [self updatePicturesCountLabel];
}

- (BOOL)quickAssetsViewControllerShouldPreselectFirstAsset:(WLQuickAssetsViewController *)controller {
    return self.startFromGallery;
}

- (void)handleAssets:(NSArray*)assets {
    __weak typeof(self)weakSelf = self;
    for (ALAsset* asset in assets) {
        WLEditPicture *picture = [WLEditPicture picture:weakSelf.mode];
        picture.assetID = asset.ID;
        picture.date = asset.date;
        [self addPicture:picture success:^{
            runQueuedOperation(@"wl_still_picture_queue",1,^(WLOperation *operation) {
                [weakSelf cropAsset:asset completion:^(UIImage *croppedImage) {
                    [picture setImage:croppedImage completion:^(id object) {
                        [operation finish];
                    }];
                }];
            });
        } failure:^(NSError *error) {
            [error show];
        }];
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

#pragma mark - WLAssetsViewControllerDelegate

- (void)assetsViewController:(id)controller didSelectAssets:(NSArray *)assets {
    [self popToRootViewControllerAnimated:YES];
    [self handleAssets:assets];
}

@end
